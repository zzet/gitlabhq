module Gitlab
  module Event
    class Notifications

      class << self

        def create_notifications(event)
          subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source)
          subscriptions.each do |subscription|
            subscription.notifications.create(event: event)
          end
        end

        def process_notification(notificaton)
          action = Event::Action.action_to_s(notification.event.action)
          target = notification.event.target.class_name.to_s
          source = notification.event.source.class_name.to_s

          mail_method = "#{action}_#{target}_#{source}email"

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
end

