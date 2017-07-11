# Handles transfers for Job class
module RestFtpDaemon
  module Remote
    class Remote
      include BmcDaemonLib::LoggerHelper
      include CommonHelpers

      # Class options
      attr_reader :log_prefix
      attr_accessor :job

      # Delegate set_info info to Job
      delegate :set_info, to: :job

      def initialize target, job, config
        # Init
        @target = target
        @config = config
        @job = job

        # Logger
        log_pipe :remote
      end

      def connect
        log_debug "remote connect: #{@target.to_connection_string}"
      end

      def size_if_exists target
        false
      end

      def remote_try_delete target
      end

      def chdir_or_create directory, mkdir = false
      end

      def upload source, target, &callback
      end

      def close
      end

      def log_context
        @job.log_context
      end

    private

      def split_path path
        return unless path.is_a? String
        return File.dirname(path), File.basename(path)
      end

      # def extract_parent path
      #   return unless path.is_a? String
      #   m = path.match(/^(.*)\/([^\/]+)\/?$/)
      #   return m[1], m[2] unless m.nil?
      # end

      def myname
        self.class.to_s
      end

    end
  end
end