# Instrumented WorkerBase

module RestFtpDaemon
  class Worker < BmcDaemonLib::WorkerBase
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

    # NewRelic instrumentation
    add_transaction_tracer :worker_init,       category: :task
    add_transaction_tracer :worker_after,      category: :task
    add_transaction_tracer :worker_process,    category: :task

  protected

    def log_context
      {
      wid: Thread.current.thread_variable_get(:wid),
      jid: Thread.current.thread_variable_get(:jid),
      }
    end

    def disabled? value
      value.nil? || value === false || value == 0
    end

  end
end