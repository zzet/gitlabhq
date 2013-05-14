class Gitlab::Event::Notifications

  class << self

    def create_notifications(event)
      if can_create_notifications?(event)
        subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source_type)

        subscriptions.each do |subscription|
          # Not send notification about changes to changes author
          # TODO. Rewrite in future with check by Entity type
          if build_notification?(subscription, event)
            subscription.notifications.create(event: event, subscriber: subscription.user)
          end
        end

      end
    end

    def can_create_notifications?(event)
      return false if event.author.username == "stepashka"
      event.deleted_related? || event.deleted_self? || event.push_event? || event.full?
      # (event.target || event.action.to_sym == :deleted) && ((::Event::Action.push_action?(event.action)) || event.source_type)
    end

    def build_notification?(subscription, event)
      if ((subscription.user != event.author) || (event.author.notification_setting && event.author.notification_setting.own_changes))
        event_data = JSON.load(event.data).to_hash
        if event_data["team_echo"].present?
          p "skip event"
          return false
        else
          return true
        end
      else
        return false
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
