class Gitlab::Event::Notification::Creator::Project < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    case event.action.to_sym
    when :created
      notifications << create_project_create_notifications(event)
    when :transfer
      notifications << create_project_move_notifications(event)
    when :imported
      notifications << create_project_import_notifications(event)
    else
      notifications = super(event)
    end

    notifications.flatten
  end

  private

  def create_project_import_notifications(event)
    project = event.source
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    namespace = project.namespace
    if namespace.is_a? Group
      subscriptions = ::Event::Subscription.by_target(namespace).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    notifications
  end

  def create_project_create_notifications(event)
    project = event.source
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    namespace = project.namespace
    if namespace.is_a? Group
      subscriptions = ::Event::Subscription.by_target(namespace).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    project.users.find_each do |member|
      subscriptions = ::Event::Subscription.by_target(member).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    notifications
  end

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

  def create_recent_notifications(event)
    @owner_changes = JSON.load(@event.data).to_hash["owner_changes"]["namespace_id"]
    @old_owner = Namespace.find(@owner_changes.first)
    @new_owner = Namespace.find(@owner_changes.last)

    if @old_owner.type == "Group"
      create_group_notifications(@old_owner, event)
      create_team_notifications(@old_owner, event)
    end
    if @new_owner.type == "Group"
      create_group_notifications(@new_owner, event)
      create_team_notifications(@new_owner, event)
    end
  end

  def create_group_notifications(group, event)
    notifications = []

    subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
      end
    end

    notifications
  end

  def create_teams_notifications(group, event)
    notifications = []

    teams = group.user_teams
    teams.each do |team|
      subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          notifications << subscription.notifications.create(event: event, subscriber: subscription.user, notification_state: :delayed)
        end
      end
    end

    notifications
  end
end
