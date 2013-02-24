class NotificationObserver < ActiveRecord::Observer
  def after_create(notification)
    Sidekiq::Client.enqueue_to(:mail_notifications, MailNotificationWorker, notification)
  end
end
