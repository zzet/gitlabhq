class Gitlab::Event::Notifications

  class << self
    def process_notification(notification)
      stored_notification = ::Event::Subscription::Notification.find(notification["id"])

      if stored_notification.event
        action = stored_notification.event.action
        target = stored_notification.event.target_type.underscore
        source = stored_notification.event.source_type.underscore

        mail_method = "#{action}_#{target}_#{source}_email"

        if stored_notification.process
          begin
            if EventNotificationMailer.respond_to?(mail_method)
              EventNotificationMailer.send(mail_method, stored_notification).deliver!
            else
              raise RuntimeError, "Undefined mail_method in notifications: #{mail_method}"
            end

            stored_notification.deliver
            stored_notification.notified_at = Time.zone.now
            stored_notification.save
          rescue Exception => ex
            stored_notification.failing
            raise RuntimeError, "Can't send notification. Email error in #{mail_method}. \r\n#{ex.message}\r\n#{ex.backtrace.join("\r\n")}"
          end
        end

      else
        raise ArgumentError, "Can't send email to notification ##{notification["id"]}. Event is unavailable."
      end
    end
  end
end
