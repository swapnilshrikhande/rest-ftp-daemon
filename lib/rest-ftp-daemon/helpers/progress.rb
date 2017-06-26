module RestFtpDaemon
  module ProgressHelpers

    def progress_update transferred, name = ""
      # Update counters
      @transfer_sent += transferred
      set_info INFO_TRANFER_SENT, @transfer_sent

      # Update job info
      percent0 = (100.0 * @transfer_sent / @transfer_total).round(0)
      set_info INFO_TRANFER_PROGRESS, percent0

      # Update bitrates
      if transferred
        @current_bitrate = progress_running_bitrate @transfer_sent
        set_info INFO_TRANFER_BITRATE,  @current_bitrate.round(0)
      end

      # Notify if requested
      progress_notify percent0, name

      # Touch my worker status
      job_touch
    end

  private

    def progress_notify percent0, name, force_notify = false
      # No delay provided ?
      return if @config[:notify_after].nil?

      # What's current time ?
      now = Time.now

      # Still too early to notify again ?
      how_long_ago = (now.to_f - @last_notify_at.to_f)
      return unless force_notify || (how_long_ago > @config[:notify_after])

      # # Update bitrates
      # @current_bitrate = progress_running_bitrate @transfer_sent
      # set_info INFO_TRANFER_BITRATE,  @current_bitrate.round(0)

      # Log progress
      stack = [
        "#{percent0} %",
        format_bytes(@transfer_sent, "B"),
        format_bytes(@current_bitrate.round(0), "bps")
        ]
      stack2 = stack.map { |txt| ("%#{LOG_PIPE_LEN.to_i}s" % txt) }.join("\t")
      log_info "progress #{stack2} \t#{name}"

      # Prepare and send notification
      job_notify :progress, status: {
        progress: percent0,
        transfer_sent: @transfer_sent,
        transfer_total: @transfer_total,
        transfer_bitrate: @current_bitrate.round(0),
        transfer_current: name,
        }

      # Remember when we last did it
      @last_notify_at = now
    end

    def progress_bitrate_delta delta_data, delta_time
      return nil if delta_time.nil? || delta_time.zero?
      8 * delta_data.to_f.to_f / delta_time
    end

    def progress_running_bitrate current_data
      return if @last_time.nil?

      # Compute deltas
      @last_data ||= 0
      delta_data = current_data - @last_data
      delta_time = Time.now - @last_time

      # Update counters
      @last_time = Time.now
      @last_data = current_data

      # Return bitrate
      progress_bitrate_delta delta_data, delta_time
    end

  end
end