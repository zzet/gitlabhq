class NotificationObserver < ActiveRecord::Observer
  observe Event::Subscription::Notification

  def after_create(notification)
    Sidekiq::Client.enqueue_to(:mail_notifications, MailNotificationWorker, notification)
  end

end
