require "get_process_mem"

module RestFtpDaemon
  module API
    class Status < Grape::API

      ### ENDPOINTS
      desc "Show daemon status"
      get "/" do
        mem = GetProcessMem.new
        status 200

        # Get counters
        counters = $counters.stats.dup

        # Amend counters with legacy attributes
        if counters[:jobs].is_a? Hash
          counters[:jobs_finished] = counters[:jobs][:finished] || 0
          counters[:jobs_failed]   = counters[:jobs][:failed] || 0
        end
        if counters[:data].is_a? Hash
          counters[:transferred] = counters[:data][:transferred] || 0
        end

        # Generate sutrcture
        return  {
          hostname: `hostname`.to_s.chomp,
          name: Conf.app_name,
          version: Conf.app_ver,
          started: Conf.app_started,
          uptime: (Time.now - Conf.app_started).round(1),
          memory: mem.bytes.to_i,
          threads: Thread.list.count,

          status: $queue.jobs_by_status,
          jobs_count: $queue.jobs_count,

          counters: counters,

          rate_by_pool: $queue.rate_by(:pool),
          rate_by_targethost: $queue.rate_by(:targethost),

          workers: $pool.worker_variables,
          }
      end

    end
  end
end
