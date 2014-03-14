class Gitlab::Event::Notification::Creator::Issueable < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << super(event)
    notifications << create_notification_for_project_subscriptions(event)
    notifications << create_notification_for_assigned(event)

    notifications.flatten
  end

  def create_notification_for_project_subscriptions(event)
    project = event.target.project
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)
  end

  def create_notification_for_assigned(event)
    if can_create_for_assigned?(event)
      create_by_event(event, event.target.assignee, :delayed)
    end
  end

  def can_create_for_assigned?(event)
    event.target.assignee.present?
  end
end
