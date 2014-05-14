class NotificationObserver < ActiveRecord::Observer
  observe Event::Subscription::Notification

  def after_commit(notification)
    if notification.send(:transaction_include_action?, :create)
      unless notification.notification_state == :delayed
        Sidekiq::Client.enqueue_to(:mail_notifications, MailNotificationWorker, notification.id)
      end
    end
  end

end
