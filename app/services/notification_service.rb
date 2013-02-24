class NotificationService
  class << self

    def create_notifications(event)
      Gitlab::Event::Notifications.create_notifications(event)
    end

    def process_noification(notification)
      Gitlab::Event::Notifications.process_noification(notification)
    end

  end
end
