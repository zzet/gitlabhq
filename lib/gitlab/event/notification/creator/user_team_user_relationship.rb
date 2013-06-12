class Gitlab::Event::Notification::Creator::UserTeamUserRelationship < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    notifications << create_team_notifications(event)
    notifications << create_user_notifications(event)

    notifications.flatten
  end

  private

  def create_team_notifications(event)
    team = event.source.user_team
    notifications = []

    subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    team.groups.each do |group|
      subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    team.projects.each do |project|
      subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    notifications
  end

  def create_user_notifications(event)
    user = event.source.user
    notifications = []

    subscriptions = ::Event::Subscription.by_target(user).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end
end
