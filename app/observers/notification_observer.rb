class NotificationObserver < ActiveRecord::Observer
  observe Event::Subscription::Notification

  def after_create(notification)
    unless notification.notification_state == :delayed
      Sidekiq::Client.enqueue_to(:mail_notifications, MailNotificationWorker, notification.id)
    end
  end

end
