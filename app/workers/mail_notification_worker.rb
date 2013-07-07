class MailNotificationWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options queue: :mail_notifications

  def perform(notification)
    benchmark.find_notification do
      notification = Event::Subscription::Notification.find(notification)
    end

    notification_type = "#{notification.event.action}_#{notification.event.target_type.underscore}_#{notification.event.source_type.underscore}_mail"

    benchmark.send :"process_#{notification_type}_notification", do
      NotificationService.process_notification(notification)
    end

    benchmark.finish
  end

end
