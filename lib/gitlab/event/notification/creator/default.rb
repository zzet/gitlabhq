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

    create_adjacent_notifications(event)

    notifications
  end

  def subscriber_can_get_notification?(subscription, event)
    #has_access(event, subscription.user) &&
    subscription.user.active? && check_event_for_brave(subscription, event) &&
      (user_not_actor?(subscription.user, event) || user_subscribed_on_own_changes?(event)) &&
      no_notification_on_event?(event, subscription)
  end

  def check_event_for_brave(subscription, event)
    return true if ["Note", "MergeRequest", "Push_summary"].include?(event.source_type)
    return true if ["Project"].include?(event.source_type) && event.action == "transfer"

    subscriber = subscription.user
    settings = subscriber.notification_setting

    return false if settings.blank?
    return true if settings.brave
    false
  end

  private

  def create_adjacent_notifications(event)

    subscription_target = nil
    subscription_source = nil

    case event.target
    when Project
      return if event.action.to_sym == :transfer

      project = event.target
      namespace = project.namespace

      if namespace
        subscription_target = namespace.type == "Group" ? namespace.becomes(Group) : namespace.becomes(User)
        subscription_source = :project
      end
    end

    if subscription_target && subscription_source
      subscribe_users_to_adjacent_resources(subscription_target, subscription_source)

      subscriptions = ::Event::Subscription.by_target(subscription_target).by_source_type_hard(subscription_source)

      subscriptions.each do |subscription|
        if subscriber_can_get_notification?(subscription, event)
          air_subscriptions = ::Event::Subscription.by_user(subscription.user).by_target(event.target).by_source_type_hard(event.source)
          if air_subscriptions.blank?
            subscription.notifications.create(event: event, subscriber: subscription.user)
          end
        end
      end

    end
  end

  def subscribe_users_to_adjacent_resources(target, source)
    ss = Event::Subscription::NotificationSetting.where(adjacent_changes: true)
    ss.each do |settings|
      user = settings.user
      subscriptions = Event::Subscription.by_user(user).by_target(target).by_source_type(:all)
      if subscriptions.any?
        tageted_subscriptions = Event::Subscription.by_user(user).by_target(target).by_source_type_hard(source)
        SubscriptionService.subscribe(user, :all, target, source) if tageted_subscriptions.blank?
      end
    end
  end

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

  def has_access(event, user)
    if event.source.present?
      entity = event.source
      has_access = user.admin?

      case entity
      when Project
        up = user.projects.find(entity)
        has_access = has_access || up.present?
      when Group
        ug = user.groups.find(entity)
        has_access = has_access || ug.present?
      when UserTeam
        ut = user.user_teams.find(entity)
        has_access = has_access || ut.present?
      else
        has_access = true
      end

      has_access
    end
  end
end
