class Gitlab::Event::Notification::Creator::TeamGroupRelationship < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_group_notifications(event)
    notifications << create_team_notifications(event)

    notifications.flatten
  end

  private

  def create_group_notifications(event)
    group = event.target.group
    notifications = []

    subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)
    #notifications << create_by_subscriptions(parent_event(event), subscriptions, :delayed)

    group.projects.each do |project|
      subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
      notifications << create_by_subscriptions(event, subscriptions, :delayed)
      #notifications << create_by_subscriptions(parent_event(event), subscriptions, :delayed)
    end

    notifications
  end

  def create_team_notifications(event)
    team = event.target.team
    notifications = []

    subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)
    #notifications << create_by_subscriptions(parent_event(event), subscriptions, :delayed)

    notifications
  end
end
