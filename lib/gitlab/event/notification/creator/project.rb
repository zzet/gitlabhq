class Gitlab::Event::Notification::Creator::Project < Gitlab::Event::Notification::Creator::Default
  def create(event)
    case event.action
    when :transfer
      notifications << create_project_move_notifications(event)
    else
      notifications = super(event)
    end

    notifications.flatten
  end

  private

  def create_project_move_notifications(event)
    project = event.source
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end
end
