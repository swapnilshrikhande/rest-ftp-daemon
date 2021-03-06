require 'singleton'

# Queue that stores all the Jobs waiting to be processed or fully processed
module RestFtpDaemon
  class JobQueue
    include Singleton
    include BmcDaemonLib::LoggerHelper
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    include CommonHelpers

    # Class options
    attr_reader :jobs

    def initialize
      # Initialize values
      @queues = {}
      @waitings = {}
      @jobs = []
      @last_id = 0

      @queues.taint          # enable tainted communication
      @waitings.taint
      taint

      # Create mutex
      @mutex = Mutex.new

      # Logger
      log_pipe :queue

      # Identifiers generator
      @prefix = identifier(JOB_IDENT_LEN)
      log_info "initialized (prefix: #{@prefix})"
    end

    def create_job params
      # Build class name and chock if it exists
      # klass = Kernel.const_get("Job#{params[:type].to_s.capitalize}") rescue nil
      klass_name = "Job#{params[:type].to_s.capitalize}"
      klass = Kernel.const_get(klass_name) rescue nil

      # If object not found, don't create a job !
      unless klass && klass < Job
        message = "can't create [#{klass_name}] for type [#{params[:type]}]"
        log_error "create_job: #{message}"
        raise QueueCantCreateJob, message
      end

      # Generate an ID and stack it
      @mutex.synchronize do
        @last_id += 1
      end
      job_id = prefixed_id(@last_id)

      # Instantiate it and return the now object
      log_info "create_job: creating [#{klass.name}] with ID [#{job_id}]"
      job = klass.new(job_id, params)

      # Push it on the queue
      push job

      return job
    end

    def generate_id
      @mutex.synchronize do
        @last_id += 1
      end
      prefixed_id @last_id
    end

    def jobs_queued
      @queues
    end

    def queued_by_pool
      result = {}
      @queues.each do |pool, jobs|
        result[pool] = jobs.count
      end
      result
    end

    def rate_by method_name
      # Init
      result = {}
      #return unless Job.new(0, {}).respond_to? method_name

      # Select only running jobs
      @jobs.each do |job|

        # Compute jobs's group, next if empty
        group = job.send(method_name)
        next if group.nil?

        # Initialize rate entry
        result[group] ||= nil

        # If job is not uploading, next !
        next unless job.status == JOB_STATUS_UPLOADING

        # Extract current rate, next if not available
        rate = job.get_info INFO_TRANFER_BITRATE
        next if rate.nil?

        # Add its current rate
        result[group] ||= 0
        result[group] += rate
      end

      # Return the rate
      result
    end

    # Queue infos
    def jobs_count
      @jobs.length
    end

    def jobs_by_status
      statuses = {}
      @jobs.group_by { |job| job.status }.map { |status, jobs| statuses[status] = jobs.size }
      statuses
    end

    # def jobs_ids
    #   @jobs.collect(&:id)
    # end

    def empty?
      @queue.empty?
    end

    # def num_waiting
    #   @waiting.size
    # end

    # Queue access
    def find_by_id id, prefixed = false
      # Build a prefixed id if expected
      id = prefixed_id(id) if prefixed
      log_info "find_by_id (#{id}, #{prefixed}) > #{id}"

      # Search in jobs queues
      @jobs.find { |item| item.id == id }
    end

    def push job
      # Check that item responds to "priorty" method
      raise "push: job should respond to: priority" unless job.respond_to? :priority
      raise "push: job should respond to: id" unless job.respond_to? :id
      raise "push: job should respond to: pool" unless job.respond_to? :pool
      raise "push: job should respond to: reset" unless job.respond_to? :reset

      @mutex.synchronize do
        # Get this job's pool & prepare queue of this pool
        pool = job.pool
        myqueue = (@queues[pool] ||= [])

        # Store the job into the global jobs list, if not already inside
        @jobs.push(job) unless @jobs.include?(job)

        # Push job into the queue, if not already inside
        myqueue.push(job) unless myqueue.include?(job)

        # Inform the job that it's been queued / reset it
        job.reset

        # Refresh queue order
        #sort_queue!(pool)
        myqueue.sort_by!(&:weight)

        # Try to wake a worker up
        begin
          @waitings[pool] ||= []
          t = @waitings[pool].shift
          t.wakeup if t
        rescue ThreadError
          retry
        end
      end
    end
    alias <<      push
    alias enq     push
    alias requeue push

    def pop pool, non_block = false
      @mutex.synchronize do
        myqueue = (@queues[pool] ||= [])
        @waitings[pool] ||= []
        loop do
          if myqueue.empty?
            raise ThreadError, "queue empty" if non_block
            @waitings[pool].push Thread.current
            @mutex.sleep
          else
            return myqueue.pop
          end
        end
      end
    end
    alias shift pop
    alias deq pop

    def clear
      @queue.clear
    end

    # Jobs acess and searching
    def jobs_with_status status
      # No status filter: return all execept queued
      if status.empty?
        @jobs.reject { |job| job.status == JOB_STATUS_QUEUED }

      # Status filtering: only those jobs
      else
        @jobs.select { |job| job.status == status.to_s }

      end
    end

    # Jobs cleanup
    def expire status, maxage, verbose = false
# FIXME: clean both @jobs and @queue
      # Init
      return if status.nil? || maxage <= 0

      # Compute oldest limit
      time_limit = Time.now - maxage.to_i
      log_info "expire limit [#{time_limit}] status [#{status}]" if verbose

      @mutex.synchronize do
        # Delete jobs from the queue when they match status and age limits
        @jobs.delete_if do |job|
          # log_debug "testing job [#{job.id}] updated_at [#{job.updated_at}]"

          # Skip if wrong status, updated_at invalid, or updated since time_limit
          next unless job.status == status
          next if job.updated_at.nil?
          next if job.updated_at >= time_limit

          # Ok, we have to clean it up ..
          log_info "expire [#{status}]: job [#{job.id}] updated_at [#{job.updated_at}]"

          # From any queues, remove it
          @queues.each do |pool, jobs|
            log_debug "#{LOG_INDENT}unqueued from [#{pool}]" if jobs.delete(job)
          end

          # Remember we have to delete the original job !
          true
        end
      end

    end

  protected

    def prefixed_id id
      "#{@prefix}.#{id}"
    end

    # NewRelic instrumentation
    add_transaction_tracer :push,                 category: :task
    add_transaction_tracer :pop,                  category: :task
    add_transaction_tracer :expire,               category: :task
    add_transaction_tracer :rate_by,              category: :task
    add_transaction_tracer :jobs_by_status,       category: :task

  end
end