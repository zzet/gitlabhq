class Gitlab::Event::Notification::Creator::Note < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = []

    return notifications if %w(deleted updated).include?(event.action)

    notifications << create_notification_for_project_subscriptions(event)
    notifications << create_notification_for_commit_author(event)
    notifications << create_notification_for_mentioned_users(event, notifications.flatten)

    notifications.flatten
  end

  def create_notification_for_project_subscriptions(event)
    project = event.target.project
    notifications = []

    subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)
  end

  def create_notification_for_commit_author(event)
    if correct_commit_author?(event)
      user = event.target.commit_author
      create_by_event(event, user, :delayed)
    end
  end

  def create_notification_for_mentioned_users(event, notifications)
    notified_user_ids = notifications.compact.map { |n| n.subscriber_id }
    user_to_notify = event.target.mentioned_users.reject { |u| notified_user_ids.include?(u.id) }
    user_to_notify.each do |user|
      create_by_event(event, user, :delayed)
    end
  end

  def correct_commit_author?(event)
    event.source.commit_author.present?
  end
end
