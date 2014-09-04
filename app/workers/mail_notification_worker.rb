class MailNotificationWorker
  @queue = :mail_notifications

  def self.perform(notification)
    notification = Event::Subscription::Notification.find(notification)
    NotificationService.process_notification(notification)
  end

end
