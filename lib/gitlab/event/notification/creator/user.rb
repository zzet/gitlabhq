class Gitlab::Event::Notification::Creator::User < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    case event.action.to_sym
    when :blocked
      notifications << create_user_block_notifications(event)
    else
      notifications = super(event)
    end

    notifications.flatten
  end

  private

  def create_user_block_notifications(event)
    user = event.source
    notifications = []

    subscriptions = ::Event::Subscription.by_target(user).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    data = JSON.load(event.data["teams"])

    teams = data["teams"]
    teams.each do |team|
      team = UserTeam.find_by_id(team["id"])
      if team.present?
        subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
        subscriptions.each do |subscription|
          if subscriber_can_get_notification?(subscription, event)
            notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
          end
        end
      end
    end

    projects = data["projects"]
    projects.each do |project|
      project = Project.find_by_id(project["id"])
      if project.present?
        subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
        subscriptions.each do |subscription|
          if subscriber_can_get_notification?(subscription, event)
            notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
          end
        end
      end
    end

    notifications
  end
end
