require "net/ftp"
require "double_bag_ftps"

# Handle FTP and FTPES transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteFTP < Remote

      # Class options
      attr_reader :ftp

      def prepare
        super
        
        # Create FTP object
        if @target.secure?
          prepare_ftpes
        else
          prepare_ftp
        end
        @ftp.passive = true
        @ftp.debug_mode = debug_enabled

        # Announce object
        log_debug "prepare chunk_size:#{format_bytes(JOB_FTP_CHUNKMB, "B")}"
      end

      def connect
        super
        log_debug "connect", @target.to_debug
        log_debug "connect [#{@target.user}]@[#{@target.host}]:[#{@target.port}]"

        # Connect remote server
        @ftp.connect @target.host, @target.port
        @ftp.login @target.user, @target.password
      end

      def size_if_exists target
        log_debug "size_if_exists [#{target.name}]"
        size = @ftp.size target.path_abs

      rescue Net::FTPPermError
        return false
      else
        return size
      end

      def try_to_remove target
        @ftp.delete target.path_abs
      rescue Net::FTPPermError
        log_debug "try_to_remove [#{target.name}] not found"
      else
        log_debug "try_to_remove [#{target.name}] removed"
      end

      def mkdir directory
        log_debug "mkdir [#{directory}]"
        @ftp.mkdir directory

      rescue StandardError => ex
        raise TargetPermissionError, ex.message
      end

      def chdir_or_create thedir, mkdir = true
        # Init, extract my parent name and my own name
        parent, current = split_path(thedir)
        log_debug "chdir_or_create mkdir[#{mkdir}] dir[#{thedir}] parent[#{parent}] current[#{current}]"

        # Access this directory
        begin
          @ftp.chdir "/#{thedir}"

        rescue Net::FTPPermError => _e

          # If not allowed to create path, that's over, we're stuck
          unless mkdir
            log_debug "  [#{thedir}] failed > no mkdir > over"
            return false
          end

          # Try to go into my parent directory
          log_debug "  [#{thedir}] failed > chdir_or_create [#{parent}]"
          chdir_or_create parent, mkdir

          # Now I was able to chdir into my parent, create the current directory
          log_debug "  [#{thedir}] failed > mkdir [#{current}]"
          mkdir current

          # Finally retry the chdir
          retry
        else
          return true
        end

      end

      def upload source, target, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "upload/ftp" if @ftp.nil?

        # Temp file if needed
        dest = target.clone
        if temp
          dest = temp
        end

        # Move to the directory
        log_debug "chdir [#{dest.dir_abs}]"
        @ftp.chdir dest.dir_abs

        # Do the transfer
        log_debug "putbinaryfile abs[#{source.path_abs}] [#{dest.name}]"
        @ftp.putbinaryfile source.path_abs, dest.name, JOB_FTP_CHUNKMB do |data|
          # Update job status after this block transfer
          yield data.bytesize, dest.name
        end
      end

      def move source, target
        log_debug "move [#{source.name}] > [#{target.name}]"
        @ftp.rename source.name, target.name
      end

      def close
        # Close init
        super

        # Close FTP connexion and free up memory
        @ftp.close
      end

      def connected?
        !@ftp.welcome.nil?
      end

    private

      def prepare_ftp
        @ftp = Net::FTP.new
      end

      def prepare_ftpes
        @ftp = DoubleBagFTPS.new
        @ftp.ssl_context = DoubleBagFTPS.create_ssl_context(verify_mode: OpenSSL::SSL::VERIFY_NONE)
        @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
      end

      def debug_enabled
        @config[:debug_ftp]
      end

    end
  end
end