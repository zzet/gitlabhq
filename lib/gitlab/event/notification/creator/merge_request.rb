class Gitlab::Event::Notification::Creator::MergeRequest < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = super(event)

    notifications << create_notification_for_project_subscriptions(event)

    notifications << create_notification_for_assigned(event) if can_create_for_assigned?(event)

    notifications << create_notification_for_mentioned_users(event, notifications)
  end

  def can_create_for_assigned?(event)
    correct_assigned?(event) && no_notification?(event, event.source.assignee)
  end

  def create_notification_for_project_subscriptions(event)
    project = event.source.project
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end
  end

  def create_notification_for_assigned(event)
    ::Event::Subscription::Notification.create(event: event, subscriber: event.source.assignee)
  end

  def correct_assigned?(event)
    event.source.assignee.present? && event.source.assignee != event.author
  end

  def no_notification?(event, user)
    return false if user.blank?
    ::Event::Subscription::Notification.where(event_id: event, subscriber_id: user).any?
  end

  def create_notification_for_mentioned_users(event, notifications)
    notified_user_ids = notifications.map { |n| n.subscriber_id }
    user_to_notify = event.source.mentioned_users.reject { |u| notified_user_ids.unclude?(u.id) }
    user_to_notify.each do |user|
      ::Event::Subscription::Notification.create(event: event, subscriber: user)
    end
  end
end
