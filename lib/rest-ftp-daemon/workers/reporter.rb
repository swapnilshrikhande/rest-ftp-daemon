module RestFtpDaemon

  # Worker used to report metrics to various services
  class ReporterWorker < Shared::WorkerBase

  protected

    def worker_init
      # Load corker conf
      config_section :reporter

      # Check that everything is OK
      return "invalid timer" unless @config[:timer].to_i > 0
      return false
    end

    def worker_after
      # Sleep for a few seconds
      worker_status WORKER_STATUS_WAITING
      sleep @config[:timer]
    end

    def worker_process
      # Announce we are working
      worker_status WORKER_STATUS_REPORTING

      # Report metrics
      do_metrics

    rescue StandardError => e
      log_error "EXCEPTION: #{e.inspect}"
      sleep 1
    end

  private

    def do_metrics
      # Get common metrics and dump them to logs
      metrics = Metrics.sample
      log_info "collected metrics", metrics

      # Transpose metrics to NewRelic metrics
      report_newrelic(metrics) if Conf.newrelic_enabled?
    end

    def report_newrelic metrics
      metrics_newrelic = {}
      metrics.each do |group, pairs|
        pairs.each do |key, value|
          name = "rftpd/#{group}/#{key}"
          ::NewRelic::Agent.record_metric(name, value)
          metrics_newrelic[name] = value
        end
      end
      if @config[:debug]
        log_debug "reported following metrics to NewRelic", metrics_newrelic
      else
        log_debug "reported all metrics to NewRelic"
      end
    end

  end
end
