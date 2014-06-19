class Gitlab::Event::Notification::Creator::Default
  # Interface method
  def create(event)
    subscriptions = ::Event::Subscription.all
    subscriptions = if event.target.present?
                      subscriptions.by_target(event.target)
                    else
                      # For deleted events
                      subscriptions.by_event_target(event)
                    end
    subscriptions = subscriptions.by_source_type(event.source_type)

    create_by_subscriptions(event, subscriptions)
  end

  def create_by_subscriptions(event, subscriptions, state = :new)
    notifications = []
    subscriptions.each do |subscription|
      if subscriber_can_get_notification?(subscription, event)
        opts = { event: event, subscriber: subscription.user,
                 notification_state: default_notification_state(event, state) }
        notifications << subscription.notifications.create(opts)
      end
    end
    notifications.flatten
  end

  # Sometime we mast send notification without subscription
  # For example notification on create MR for assignee
  def create_by_event(event, user, state = :new)
    opts = { event: event, subscriber: user, notification_state: state }
    ::Event::Subscription::Notification.create(opts) if no_notification_on_event?(event, user)
  end

  def no_notification_on_event?(event, user)
    notifications = ::Event::Subscription::Notification.where(event_id: event, subscriber_id: user)
    return false if notifications.any?

    child_event_ids = ::Event.where(parent_event_id: event).pluck(:id)
    child_notifications = ::Event::Subscription::Notification.where(event_id: child_event_ids, subscriber_id: user)
    return false if child_notifications.any?

    parent_event = event.parent_event
    return true if parent_event.blank?

    notifications = ::Event::Subscription::Notification.where(event_id: parent_event, subscriber_id: user)
    return true if notifications.blank? && no_notification_on_event?(parent_event, user)

    false
  end

  # Subscriber can get notification if
  # 1) User active
  # 2) User not actor
  # 3) User has access on entity (not implemented)
  # 2) Filter brave subscriptions
  # 3) No notifications on event created already
  def subscriber_can_get_notification?(subscription, event)
    subscription.user.active? &&
      no_notification_on_event?(event, subscription.user) &&
      check_event_for_brave(subscription, event) &&
      (user_not_actor?(subscription.user, event) || user_subscribed_on_own_changes?(event))
    #&& check_event_summary_subscriptions(subscription)
    #has_access(event, subscription.user)
  end

  # Brave mode for filter events on which may created notifications
  # Allowed to create notification if
  # 1) source type Note, MergeRequest, Push
  # 2) Project was transfered
  def check_event_for_brave(subscription, event)
    return true if ["Note", "MergeRequest", "Push"].include?(event.source_type)
    return true if ["Project"].include?(event.source_type) && event.action == "transfer"

    subscriber = subscription.user
    settings = subscriber.notification_setting

    return false if settings.blank?
    return true if settings.brave
    false
  end

  def parent_event event
    return event if event.parent_event.nil?
    parent_event event.parent_event
  end

  def check_event_summary_subscriptions(subscription)
    subscriber = subscription.user
    settings = subscriber.notification_setting
    return true if settings.blank? || !settings.brave

    summaries = Event::Summary.by_subscription(subscription)
    return true if summaries.blank?

    summaries.detect { |s| s.enabled? }.nil?
  end

  def user_not_actor?(user, event)
    user != event.author
  end

  def user_subscribed_on_own_changes?(event)
    event.author.notification_setting && event.author.notification_setting.own_changes
  end

  private

  def default_notification_state(event, current_state)
    return current_state if current_state != :new
    # On all destroy events notifications :delayed
    # Becouse it action often generated spam with dependent: :destroy action
    return :delayed if event.system_action.to_sym == :destroy

    action = event.action.to_sym

    case event.target_type
    when "Group"
      case action
      when :created, :members_added, :teams_added
        return :delayed
      end
    when "Team"
      case action
      when :created, :members_added, :projects_added, :groups_added
        return :delayed
      end
    when "Issue", "MergeRequest", "Note"
      case action
      when :created
        return :delayed
      end
    end
    current_state
  end

  def has_access(event, user)
    if event.source.present?
      entity = event.target
      has_access = user.admin?

      case entity
      when Project
        up = user.projects.find(entity)
        has_access = has_access || up.present?
      when Group
        ug = user.groups.find(entity)
        has_access = has_access || ug.present?
      when Team
        ut = user.teams.find(entity)
        has_access = has_access || ut.present?
      else
        has_access = true
      end

      has_access
    end
  end
end
