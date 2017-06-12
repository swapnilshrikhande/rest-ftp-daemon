require "net/sftp"

# Handle sFTP transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteSFTP < Remote

      # Class options
      attr_reader :sftp

      # def prepare
      # end

      def connect
        super

        # Connect init
        log_debug "connect", @target.to_debug
        log_debug "connect [#{@target.user}]@[#{@target.host}]:[#{@target.port}]"

        # Debug level
        if debug_enabled
          verbosity = Logger::DEBUG 
        else
          verbosity = false
        end

        # Connect remote server
        @sftp = Net::SFTP.start(@target.host.to_s, @target.user.to_s,
            password: @target.password.to_s,
            verbose: verbosity,
            port: @target.port,
            non_interactive: true,
            timeout: DEFAULT_SFTP_TIMEOUT
            )
      end

      def size_if_exists target
        log_debug "size_if_exists [#{target.name}]"
        stat = @sftp.stat! target.path_abs

      rescue Net::SFTP::StatusException
        return false
      else
        return stat.size
      end

      def remove! target
        log_debug "remove! [#{target.name}]"
        @sftp.remove target.path_abs

      rescue Net::SFTP::StatusException
        log_debug "#{LOG_INDENT}[#{target.name}] file not found"
      else
        log_debug "#{LOG_INDENT}[#{target.name}] removed"
      end

      def mkdir directory
        log_debug "mkdir [#{directory}]"
        @sftp.mkdir! directory

        rescue StandardError => ex
          raise TargetPermissionError, ex.message
      end

      def chdir_or_create directory, mkdir = false
        # Init, extract my parent name and my own name
        log_debug "chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
        parent, _current = split_path(directory)

        # Access this directory
        begin
          @sftp.opendir! directory

        rescue Net::SFTP::StatusException => _e
          # If not allowed to create path, that's over, we're stuck
          return false unless mkdir

          # Recurse upward
          chdir_or_create parent, mkdir

          # Now I was able to chdir into my parent, create the current directory
          mkdir directory

          # Finally retry the chdir
          retry
        else
          return true
        end

        # We should never get here
        raise JobTargetShouldBeDirectory
      end

      def upload source, target, use_temp_name = false, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "upload/sftp" if @sftp.nil?

        # Temp file if needed
        dest = target.clone
        if use_temp_name
          dest.generate_temp_name!
        end

        # Do the transfer
        @sftp.upload! source.path_abs, dest.path_abs do |event, _uploader, *args|
          case event
          when :open then
            # args[0] : file metadata
          when :put then
            # args[0] : file metadata
            # args[1] : byte offset in remote file
            # args[2] : data being written (as string)
            # puts "writing #{args[2].length} bytes to #{args[0].remote} starting at #{args[1]}"

            # Update job status after this block transfer
            yield args[2].length, dest.name

          when :close then
            # args[0] : file metadata
          when :mkdir
            # args[0] : remote path name
          when :finish
          end

        end
      end

      def move source, target
        @sftp.rename! source.path_abs, target.path_abs, 0x00000001
      end

      def close
        # Close init
        super
      end

      def connected?
        @sftp && !@sftp.closed?
      end
    
      def debug_enabled
        @config[:debug_sftp]
      end

    end
  end
end