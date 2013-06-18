class Gitlab::Event::Notification::Creator::Note < Gitlab::Event::Notification::Creator::Default
  def create(event)
    notifications = super(event)

    notifications << create_notification_for_commit_author(event) if can_create_for_commit_author?(event)
  end

  def can_create_for_commit_author?(event)
    event.source.commit_author.present? && event.source.commit_author != event.author
  end

  def create_notification_for_commit_author(event)
    ::Event::Subscription::Notification.create(event: event, subscriber: event.source.commit_author)
  end
end
