class Gitlab::Event::Notification::Creator::MergeRequest < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = super(event)

    notifications << create_notification_for_assigned(event) if can_create_for_assigned?(event)
  end

  def can_create_for_assigned?(event)
    correct_assigned?(event) && no_notification?(event, event.source.assignee)
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
end
