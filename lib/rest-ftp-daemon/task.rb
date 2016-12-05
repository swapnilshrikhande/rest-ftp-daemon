module RestFtpDaemon
  class Task
    include BmcDaemonLib::LoggerHelper

    # Class options
    attr_reader :jobs
    attr_reader :name
    # attr_reader :fileset
    attr_accessor :log_context
    attr_accessor :inputs
    attr_accessor :outputs
    # @fileset  = "unknown"

    def initialize name, opts = {}
      # Init context
      @inputs   = []
      @outputs   = []
      @name     = name
      @log_context = {}

      # Import attributes
      @inputs << opts[:input]   if opts[:input]# || :none
      @outputs << opts[:output] if opts[:output]# || :none

      # Enable logging
      log_pipe  :workflow
    end

    def do_before
      instvar :inputs
    end

    def do_after
      instvar :outputs
    end

    def instvar var
      items = instance_variable_get("@#{var}")

      if items.is_a? Array
        log_debug "#{var}  \t #{items.object_id}", items.map(&:path)
      else
        log_error "#{var}  \t NOT AN ARRAY" 
      end
    end

  protected

    def work_debug
      @inputs.each do |t|
        out = t.clone
        out.name = "#{t.name}-#{@name}"
        @outputs << out
      end
    end

  private

  
    # def log_context
    #   {
    #     wid: @wid,
    #     jid: @jid,
    #     id: name
    #   }
    # end

  end
end