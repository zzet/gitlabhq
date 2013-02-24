class MailNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :mail_notifications

  def perform(notification)
    NotificationService.process_notification(notification)
  end

  #def self.perform(notification)
    #NotificationService.process_notification(notification)
  #end
end
