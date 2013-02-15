module Gitlab
  module Event
    module Notifications
      def trigger(action, user, data = self, target = self, detailed_event = "")
        target = target.class.name unless target.is_a? String
        event = "gitlab.#{action}.#{target}".downcase
        event << ".#{detailed_event}" unless detailed_event.blank?

        ActiveSupport::Notifications.instrument event, {target: target, user: user, data: data}
      end
    end
  end
end

ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker.new)
