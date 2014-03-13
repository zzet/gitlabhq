class Gitlab::Event::Notification::Creator::UsersGroup < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_group_notification(event)
    notifications << create_user_notification(event)

    notifications.flatten
  end

  def create_group_notification(event)
    group = event.target.group
    notifications = []

    subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
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
