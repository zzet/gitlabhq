class Gitlab::Event::Notification::Creator::Project::ProjectImported < Gitlab::Event::Notification::Creator::Default
  def create(event)
    project = event.target
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    namespace = project.namespace
    if namespace.is_a? Group
      subscriptions = ::Event::Subscription.by_target(namespace).by_source_type(event.source_type)
      notifications << create_by_subscriptions(event, subscriptions, :delayed)
    end

    notifications
  end
end
