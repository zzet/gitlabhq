class Gitlab::Event::Notification::Creator::Project::ProjectTransfered < Gitlab::Event::Notification::Creator::Default
  def create(event)
    project = event.target
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    # TODO check
    #project.users.find_each do |member|
      #notifications << create_by_event(event, member, :delayed)
    #end

    notifications
  end
end
