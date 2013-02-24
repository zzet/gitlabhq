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
      end
    end
  end
end

ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker.new)
