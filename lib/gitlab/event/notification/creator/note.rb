class Gitlab::Event::Notification::Creator::Note < Gitlab::Event::Notification::Creator::Default
  def create(event)
    return [] if %(deleted updated).include?(event.action)

    notifications = super(event)

    notifications << create_notification_for_commit_author(event) if can_create_for_commit_author?(event)

    notifications << create_notification_for_mentioned_users(event, notifications.flatten)
  end

  def can_create_for_commit_author?(event)
    correct_commit_author?(event) && no_notification?(event, event.source.commit_author)
  end

  def create_notification_for_commit_author(event)
    ::Event::Subscription::Notification.create(event: event, subscriber: event.source.commit_author, notification_state: :delayed)
  end

  def correct_commit_author?(event)
    event.source.commit_author.present? && event.source.commit_author != event.author
  end

  def no_notification?(event, user)
    notifications = ::Event::Subscription::Notification.where(event_id: event, subscriber_id: user)
    return false if notifications.any?

    parent_event = parent_event_for event
    return true if parent_event.blank?

    notifications = ::Event::Subscription::Notification.where(event_id: parent_event, subscriber_id: user)
    return true if notifications.blank? && no_notification?(parent_event, user)

    false
  end

  def create_notification_for_mentioned_users(event, notifications)
    notified_user_ids = notifications.map { |n| n.subscriber_id }
    user_to_notify = event.source.mentioned_users.reject { |u| notified_user_ids.include?(u.id) }
    user_to_notify.each do |user|
      ::Event::Subscription::Notification.create(event: event, subscriber: user, notification_state: :delayed) if no_notification?(event, user)
    end
  end
end
