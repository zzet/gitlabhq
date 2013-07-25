class Gitlab::Event::Notification::Creator::UsersProject < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_project_notification(event)
    notifications << create_user_notification(event)

    notifications.flatten
  end

  def create_project_notification(event)
    project = event.source.project
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end

  def create_user_notification(event)
    user = event.source.user
    notifications = []

    subscriptions = ::Event::Subscription.by_target(user).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end
end
