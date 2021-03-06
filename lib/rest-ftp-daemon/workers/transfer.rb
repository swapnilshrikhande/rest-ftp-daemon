# Worker used to process Jobs

module RestFtpDaemon
  class TransferWorker < Worker

  protected

    def worker_init
      # Load standard config
      config_section    :transfer
      @endpoints        = Conf[:endpoints]

      # Timeout and retry config
      return "timeout disabled"  if disabled?(@config[:timeout])
      return "invalid timeout" unless @config[:timeout].to_i > 0

      # Log that
      log_info "worker_init", {
        pool: @pool,
        timeout: @config[:timeout]
      }

      return false
    end

    def worker_after
      # Clean worker status
      worker_set_jid nil
    end

  private

    def worker_process
      # Wait for a job to be available in the queue
      worker_status WORKER_STATUS_WAITING
      job = RestFtpDaemon::JobQueue.instance.pop @pool

      # Work on this job
      job_process job

      # Clean job status
      job.wid = nil
      #sleep 1

      # Handle the retry if needed
      job_result job
    end

    def job_process job
      # Prepare job and worker for processing
      worker_set_jid job.id
      worker_status WORKER_STATUS_RUNNING, job
      job.wid = Thread.current.thread_variable_get :wid

      # Processs this job protected by a timeout
      log_info "job_process: start working"
      Timeout.timeout(@config[:timeout], RestFtpDaemon::JobTimeout) do
        job.start
      end

      # Increment total processed jobs count
      RestFtpDaemon::Counters.instance.increment :jobs, :processed

    rescue RestFtpDaemon::JobTimeout => ex
      log_error "job_process: TIMEOUT: started_at[#{job.started_at}] started_since[#{job.started_since}] #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_TIMEOUT, job

      # Inform the job
      job.oops_end(:timeout, ex) unless job.nil?

    rescue RestFtpDaemon::AssertionFailed, RestFtpDaemon::JobAttributeMissing, StandardError => ex
      log_error "job_process: CRASHED: ex[#{ex.class}] #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED

      # Inform the job
      job.oops_end(:crashed, ex) unless job.nil?
    end

    def job_result job
      # If job status requires a retry, just restack it
      if !job.error
        # Processing successful
        log_info "job_result: finished successfully"
        worker_status WORKER_STATUS_FINISHED, job

      elsif error_not_eligible(job)
        log_error "job_result: not retrying [#{job.error}] retry_on not eligible"

      elsif error_reached_for(job)
        log_error "job_result: not retrying [#{job.error}] retry_for reached [#{@config[:retry_for]}s]"

      elsif error_reached_max(job)
        log_error "job_result: not retrying [#{job.error}] retry_max reached #{tentatives(job)}"

      else
        # Delay cannot be negative, and will be 1s minimum
        retry_after = [@config[:retry_after] || DEFAULT_RETRY_AFTER, 1].max
        log_info "job_result: retrying job [#{job.id}] in [#{retry_after}s] - tried #{tentatives(job)}"

        # Wait !
        worker_status WORKER_STATUS_RETRYING, job
        sleep retry_after
        log_debug "job_result: job [#{job.id}] requeued after [#{retry_after}s] delay"

        # Now, requeue this job
        RestFtpDaemon::JobQueue.instance.requeue job
      end
    end

    def error_not_eligible job
      # No, if no eligible errors
      return true unless @config[:retry_on].is_a?(Enumerable)

      # Tell if this error is in the list
      return !@config[:retry_on].include?(job.error.to_s)
    end

    def error_reached_for job
      # Not above, if no limit definded
      return false unless @config[:retry_for]

      # Job age above this limit
      return job.created_since >= @config[:retry_for]
    end

    def error_reached_max job
      # Not above, if no limit definded
      return false unless @config[:retry_max]

      # Job age above this limit
      return job.tentatives >= @config[:retry_max]
    end

    def worker_set_jid jid
      Thread.current.thread_variable_set :jid, jid
      Thread.current.thread_variable_set :updated_at, Time.now
    end

    def tentatives job
      "[#{job.tentatives}/#{@config[:retry_max]}]"
    end

  end
end