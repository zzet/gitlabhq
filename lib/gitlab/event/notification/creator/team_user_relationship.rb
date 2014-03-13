class Gitlab::Event::Notification::Creator::TeamUserRelationship < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_team_notifications(event)
    notifications << create_user_notifications(event)

    notifications.flatten
  end

  private

  def create_team_notifications(event)
    team = event.target.team
    notifications = []

    subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    team.groups.each do |group|
      subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
      notifications << create_by_subscriptions(event, subscriptions, :delayed)
    end

    team.projects.each do |project|
      subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
      notifications << create_by_subscriptions(event, subscriptions, :delayed)
    end

    notifications
  end

  def create_user_notifications(event)
    user = event.target.user
    notifications = []

    subscriptions = ::Event::Subscription.by_target(user).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    notifications
  end
end
