class Gitlab::Event::Notification::Creator::UserTeamProjectRelationship < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_team_notifications(event)
    notifications << create_project_notifications(event)
    notifications << create_user_notifications(event)

    notifications.flatten
  end

  private

  def create_project_notifications(event)
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

  def create_team_notifications(event)
    team = event.source.user_team
    notifications = []

    subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end

  def create_user_notifications(event)
    team = event.source.user_team
    notifications = []

    team.members.each do |member|
      subscriptions = ::Event::Subscription.by_target(member).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    notifications
  end

  def subscriber_can_get_notification?(subscription, event)
    return false if event.parent_event.present? && event.parent_event.action.to_sym == :transfer
    super(subscription, event)
  end
end
