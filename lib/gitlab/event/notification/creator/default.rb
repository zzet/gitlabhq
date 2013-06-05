class Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source_type)

    subscriptions.each do |subscription|
      # Not send notification about changes to changes author
      # TODO. Rewrite in future with check by Entity type
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user)
      end
    end

    notifications
  end

  def subscriber_can_get_notification?(subscription, event)
    subscription.user.active? &&
      (user_not_actor?(subscription.user, event) || user_subscribed_on_own_changes?(event)) &&
      no_notification_on_event?(event, subscription)
  end

  private

  def parent_event_for(event)
    event.parent_event
  end

  def no_notification_on_event?(event, subscription)
    notifications = ::Event::Subscription::Notification.where(event_id: event, subscriber_id: subscription.user)
    return false if notifications.any?

    parent_event = parent_event_for event
    return true if parent_event.blank?

    notifications = ::Event::Subscription::Notification.where(event_id: parent_event, subscriber_id: subscription.user)
    return true if notifications.blank? && no_notification_on_event?(parent_event, subscription)

    false
  end

  def user_not_actor?(user, event)
    user != event.author
  end

  def user_subscribed_on_own_changes?(event)
    event.author.notification_setting && event.author.notification_setting.own_changes
  end
end
