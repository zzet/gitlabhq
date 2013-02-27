module Gitlab
  module Event
    class Notifications

      class << self

        def create_notifications(event)
          if event.target && ((event.action == "pushed") || event.source)
            subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source_type)
            subscriptions.each do |subscription|
              subscription.notifications.create(event: event)
            end
          end
        end

        def process_notification(notification)
          stored_notification = ::Event::Subscription::Notification.find(notification["id"])

          if stored_notification.event
            action = stored_notification.event.action
            target = stored_notification.event.target_type.downcase
            source = stored_notification.event.source_type.downcase

            mail_method = "#{action}_#{target}_#{source}_email"

            ::Event::Subscription::Notification.transaction do

              stored_notification.process
              stored_notification.save

              begin

                if EventNotificationMailer.respond_to?(mail_method)
                  EventNotificationMailer.send(mail_method, stored_notification).deliver!
                else
                  Rails.logger.info "Undefined mail_method in notifications: #{mail_method}"
                  EventNotificationMailer.default_email(stored_notification)
                end

                stored_notification.deliver
                stored_notification.notified_at = Time.zone.now
              rescue
                stored_notification.failing
              end

              stored_notification.save
            end

          else
            Rails.logger.warn("Can't send email to notification ##{notification["id"]}. Event is deleted.")
          end
        end

      end

    end
  end
end

