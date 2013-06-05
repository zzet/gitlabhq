class MailNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :mail_notifications

  def perform(notification)
    notification = Event::Subscription::Notification.find(notification)
    NotificationService.process_notification(notification)
  end

end
