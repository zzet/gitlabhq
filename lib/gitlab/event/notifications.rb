module Gitlab
  module Event
    class Notifications

      class << self

        def create_notifications(event)
          if (event.target || event.action == "deleted") && ((event.action == "pushed") || event.source)
            subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source_type)

            subscriptions.each do |subscription|
              # Not send notification about changes to changes author
              # TODO. Rewrite in future with check by Entity type
              if subscription.user != event.author
                subscription.notifications.create(event: event)
              end
            end

          end
        end

        def process_notification(notification)
          stored_notification = ::Event::Subscription::Notification.find(notification["id"])

          if stored_notification.event
            action = stored_notification.event.action
            target = stored_notification.event.target_type.underscore
            source = stored_notification.event.source_type.underscore

            mail_method = "#{action}_#{target}_#{source}_email"

            ::Event::Subscription::Notification.transaction do

              stored_notification.process
              stored_notification.save

              begin

                if EventNotificationMailer.respond_to?(mail_method)
                  EventNotificationMailer.send(mail_method, stored_notification).deliver!
                else
                  raise RuntimeError, "Undefined mail_method in notifications: #{mail_method}"
                end

                stored_notification.deliver
                stored_notification.notified_at = Time.zone.now
              rescue Exception => ex
                stored_notification.failing
                raise RuntimeError, "Can't send notification. Email error in #{mail_method}. \r\n#{ex.message}\r\n#{ex.backtrace.join("\r\n")}"
              end

              stored_notification.save
            end

          else
            raise ArgumentError, "Can't send email to notification ##{notification["id"]}. Event is unavailable."
          end
        end

      end

    end
  end
end

