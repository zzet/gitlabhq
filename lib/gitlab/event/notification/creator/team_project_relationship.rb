class Gitlab::Event::Notification::Creator::TeamProjectRelationship < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_team_notifications(event)
    notifications << create_project_notifications(event)
    notifications << create_user_notifications(event)

    notifications.flatten
  end

  private

  def create_project_notifications(event)
    project = event.target.project
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    notifications
  end

  def create_team_notifications(event)
    team = event.target.team
    notifications = []

    subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    notifications
  end

  def create_user_notifications(event)
    team = event.target.team
    notifications = []

    team.members.each do |member|
      subscriptions = ::Event::Subscription.by_target(member).by_source_type(event.source_type)
      notifications << create_by_subscriptions(event, subscriptions, :delayed)
    end

    notifications
  end
end
