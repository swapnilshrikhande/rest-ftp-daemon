module RestFtpDaemon
  class TaskExport < Task
    include TransferHelpers

    # Task attributes
    ICON = "export"

    def do_before
      # Init
      super

      # Check input
      end

return
      # Check outputs
      unless target_loc.uri_is? URI::FILE
        raise RestFtpDaemon::TargetUnsupported, "task output: invalid file type"
      end
      dump_locations "target_loc", [target_loc]

      # Guess target file name, and fail if present while we matched multiple sources
      if target_loc.name && @inputs.count>1
        raise RestFtpDaemon::TargetDirectoryError, "target should be a directory when matching many files"
      end

      # Some init
      @transfer_sent = 0
      set_info INFO_SOURCE_PROCESSED, 0
      # Prepare remote object
      case target_loc.uri
      when URI::FTP
        log_info "do_before target_method FTP"
        # options[:debug] = @config[:debug_ftp]
        @remote = Remote::RemoteFTP.new target_loc, log_context, @config[:debug_ftp]
      when URI::FTPES, URI::FTPS
        log_info "do_before target_method FTPES/FTPS"
        @remote = Remote::RemoteFTP.new target_loc, log_context, @config[:debug_ftps], :ftpes
      when URI::SFTP
        log_info "do_before target_method SFTP"
        @remote = Remote::RemoteSFTP.new target_loc, log_context, @config[:debug_sftp]
      when URI::S3
        log_info "do_before target_method S3"
        @remote = Remote::RemoteS3.new target_loc, log_context, @config[:debug_s3]
        log_info "do_before target_method FILE"
        @remote = Remote::RemoteFile.new target_loc, log_context, @config[:debug_file]
      else
        message = "unknown scheme [#{target_loc.scheme}] [#{target_uri.class.name}]"
        log_info "do_before #{message}"
        raise RestFtpDaemon::TargetUnsupported, message
      end

      # Plug this Job into @remote to allow it to log
      @remote.job = self
    end

    def do_work
      # Connect to remote server and login
      set_status Job::STATUS_EXPORT_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status Job::STATUS_EXPORT_CHDIR
      @remote.chdir_or_create target_loc.dir_abs, get_option(:transfer, :mkdir)

      # Compute total files size
      @transfer_total = @inputs.collect(&:size).sum
      set_info INFO_TRANSFER_TOTAL, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []
      @inputs.each do |source|
        # Build final target, add the source file name if noneh
        target.name = source.name unless target.name
        target = target_loc.clone

        # Do the transfer, for each file
        remote_upload source, target, get_option(:transfer, :overwrite)

    end

  protected

    def do_after
      # Close FTP connexion and free up memory
      @remote.close
      # log_info "do_after close connexion, update status and counters"

      # Free @remote object
      @remote = nil

      # Update job status
      set_status Job::STATUS_EXPORT_DISCONNECTING
      @finished_at = Time.now

      # Update counters
      RestFtpDaemon::Counters.instance.increment :jobs, :finished
      RestFtpDaemon::Counters.instance.add :data, :transferred, @transfer_total
    end

  end
end