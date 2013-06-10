class Gitlab::Event::Notification::Creator::Project < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = super(event)

    notifications << create_adjacent_notifications(event)
  end

  def create_adjacent_notifications(event)
    subscription_target = nil
    subscription_source = nil

    project = event.target
    namespace = project.namespace

    if namespace
      subscription_target = namespace.type == "Group" ? namespace.becomes(Group) : namespace.becomes(User)
      subscription_source = :project
    end

    if subscription_target && subscription_source
      subscribe_users_to_adjacent_resources(subscription_target, subscription_source)

      subscriptions = ::Event::Subscription.by_target(subscription_target).by_source_type_hard(subscription_source)

      subscriptions.each do |subscription|
        if build_notification?(subscription, event)
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

  def create_notification_for_commit_author(event)
    ::Event::Subscription::Notification.create(event: event, subscriber: event.source.commit_author)
  end
end
