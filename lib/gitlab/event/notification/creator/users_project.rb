class Gitlab::Event::Notification::Creator::UsersProject < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_project_notification(event)
    notifications << create_user_notification(event)

    notifications.flatten
  end

  def create_project_notification(event)
    project = event.target.project
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    notifications
  end

  def create_user_notification(event)
    user = event.target.user
    notifications = []

    subscriptions = ::Event::Subscription.by_target(user).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    notifications
  end
end
