class Gitlab::Event::Hierarchy::Middleware

  def initialize(appl)
    @appl = appl
    Thread.current[:event_action_collector] = ::EventHierarchyWorker
  end

  def call(env)
    Thread.current[:event_action_collector].reset

    status, headers, body = @appl.call(env)

    Thread.current[:event_action_collector].reset

    [status, headers, body]
  end
end
