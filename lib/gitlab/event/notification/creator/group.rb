class Gitlab::Event::Notification::Creator::Group < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    case event.action.to_sym
    when :members_added, :teams_added
      notifications << create_project_mass_add_notifications(event)
    else
      notifications = super(event)
    end

    notifications.flatten
  end

  private

  def create_project_mass_add_notifications(event)
    group = event.source
    notifications = []

    subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end
end
