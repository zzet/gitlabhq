class Gitlab::Event::Notification::Creator::Team < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    case event.action.to_sym
    when :members_added, :groups_added, :projects_added, :created
      notifications << create_project_mass_add_notifications(event)
    else
      notifications = super(event)
    end

    notifications.flatten
  end

  private

  def create_project_mass_add_notifications(event)
    team = event.source
    notifications = []

    subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end
end
