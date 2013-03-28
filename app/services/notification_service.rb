class NotificationService
  class << self

    def create_notifications(event)
      Rails.logger.info "Create notifications by event: ##{event.id}"
      Gitlab::Event::Notification.create_notifications(event)
    end

    def process_notification(notification)
      Gitlab::Event::Notification.process_notification(notification)
    end

  end
end
