class NotificationService
  class << self

    def create_notifications(event)
      Gitlab::Event::Notification.create_notifications(event)
    end

    def process_notification(notification)
      Gitlab::Event::Notification.process_notification(notification)
    end

  end
end
