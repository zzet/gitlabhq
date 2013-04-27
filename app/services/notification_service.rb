class NotificationService
  class << self

    def create_notifications(event)
      Gitlab::Event::Notifications.create_notifications(event)
    end

    def process_notification(notification)
      Gitlab::Event::Notifications.process_notification(notification)
    end

  end
end
