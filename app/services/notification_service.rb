class NotificationService
  class << self
    def create_notifications(event)
      subscriptions = Event::Subscription.on_event(event)
      subscriptions.each do |subscription|
        subscription.notifications.create(event: event)
      end
    end

    def process_noifications
      process_instantaneous_noifications
    end

    private

    def process_instantaneous_noifications
      notifications = Event::Subscription::Notification.instantaneous
      notifications.each do |notification|
        action = Event::Action.action_to_s(notification.event.action)
        target = notification.event.target.class_name.to_s

        mail_method = "#{action}_#{target}_email"

        if EventNotificationMailer.respond_to?(mail_method)
          EventNotificationMailer.send(mail_method, notification)
        else
          Rails.logger.info "undefined #{mail_method}"
          EventNotificationMailer.dafault_email(notification)
        end
      end
    end
  end
end
