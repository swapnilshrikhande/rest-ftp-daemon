require 'streamio-ffmpeg'

module RestFtpDaemon
  class JobVideo < Job

    # Process job
    def before
      log_info "JobVideo.before source_loc.path: #{@source_loc.path}"
      log_info "JobVideo.before target_loc.path: #{@target_loc.path}"

      # Ensure source and target are FILE
      raise RestFtpDaemon::SourceNotSupported, @source_loc.scheme   unless source_uri.is_a? URI::FILE
      raise RestFtpDaemon::TargetNotSupported, @target.scheme       unless target_uri.is_a? URI::FILE
    end

    def work
      # Guess source files from disk
      set_status JOB_STATUS_TRANSFORMING
      sources = scan_local_paths @source_loc.path
      raise RestFtpDaemon::SourceNotFound if sources.empty?

      # Add the source file name if none found in the target path
      target_final = @target_loc.clone
      target_final.name = @source_loc.name unless target_final.name
      log_info "JobVideo.work target_final.path [#{target_final.path}]"

      # Ensure target directory exists
      log_info "JobVideo.work mkdir_p [#{@target_loc.dir}]"
      FileUtils.mkdir_p @target_loc.dir

      # Do the work, for each file
      set_info :source, :current, @source_loc.name
      video_command @source_loc, target_final

      # Done
      set_info :source, :current, nil

    rescue FFMPEG::Error => exception
      return oops :ended, exception, "ffmpeg_error"
    end

    def after
      # Done
      set_info :source, :current, nil
    end

  protected

    def video_command source, target
      log_info "JobVideo.video_command [#{source.name}]: [#{source.path}] > [#{target.path}]"
      set_info :source, :current, source.name

      # Read info about source file
      movie = FFMPEG::Movie.new(source.path)

      # Build options
      ffmpeg_custom_options = {
        audio_codec: @video_ac,
        video_codec: @video_vc,
        custom: ffmpeg_custom_option_array,
        }
      set_info :work, :ffmpeg_custom_options, ffmpeg_custom_options

      # Build command
      movie.transcode(target.path, ffmpeg_custom_options) do |ffmpeg_progress|
        set_info :work, :ffmpeg_progress, ffmpeg_progress

        percent0 = (100.0 * ffmpeg_progress).round(0)
        set_info :work, :progress, percent0

        log_debug "progress #{ffmpeg_progress}"
      end
    end

    def ffmpeg_custom_option_array
      # Ensure options ar in the correct format
      return [] unless @video_custom.is_a? Hash
      # video_custom_parts = @video_custom.to_s.scan(/(?:\w|"[^"]*")+/)

      # Build the final array
      custom_parts = []
      @video_custom.each do |name, value|
        custom_parts << "-#{name}"
        custom_parts << value.to_s
      end

      # Return this
      return custom_parts
    end

  end
end



