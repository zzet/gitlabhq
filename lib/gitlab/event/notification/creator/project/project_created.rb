class Gitlab::Event::Notification::Creator::Project::ProjectCreated < Gitlab::Event::Notification::Creator::Default
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

    project.users.find_each do |member|
      subscriptions = ::Event::Subscription.by_target(member).by_source_type(event.source_type)
      notifications << create_by_subscriptions(event, subscriptions, :delayed)
      # TODO check
      #notifications << create_by_event(event, member, :delayed)
    end

    notifications
  end
end
