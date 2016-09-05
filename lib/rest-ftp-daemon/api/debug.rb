require "grape"

module RestFtpDaemon
  module API
    class Debug < Grape::API
      include BmcDaemonLib

      ### HELPERS
      helpers do

        def debug_metrics
          Metrics.sample
        end

        def debug_encodings
          # Encodings
          encodings = {}
          jobs = RestFtpDaemon::JobQueue.instance.jobs

          jobs.each do |job|
            # here = out[job.id] = {}
            me = encodings[job.id] = {}

            me[:error] = job.error.encoding.to_s unless job.error.nil?
            me[:status] = job.status.encoding.to_s unless job.status.nil?

            RestFtpDaemon::Job::IMPORTED.each do |name|
              value = job.send(name)
              me[name] = value.encoding.to_s if value.is_a? String
            end

            job.infos.each do |name, value|
              me["infos_#{name}"] = value.encoding.to_s if value.is_a? String
            end
          end
        end

      end

      ### ENDPOINTS
      desc "debug"#, hidden: true
      get "/" do

        # Extract routes
        routes = []
        RestFtpDaemon::API::Root.routes.each do |route|
          routes << {
            url: "#{route.options[:method]} #{route.pattern.path}",
            vars: route.instance_variables,
            options: route.options
            }

        end

        # Build response
        return  {
          metrics: debug_metrics,
          encodings: debug_encodings,
          routes: routes,
          }
      end

    end
  end
end
