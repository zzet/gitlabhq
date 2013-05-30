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
    (subscription.user != event.author) || user_subscribed_on_own_changes?(event)
  end

  private

  def user_subscribed_on_own_changes?(event)

    p event.author.notification_setting && event.author.notification_setting.own_changes
    event.author.notification_setting && event.author.notification_setting.own_changes
  end
end
