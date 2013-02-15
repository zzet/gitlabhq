module Gitlab
  module Event
    class Notifications
      cattr_accessor :current_user

      def self.trigger(action, target, user = nil, data = nil, detailed_event = "")
        data = target if data.blank?
        target = target.class.name unless target.is_a? String
        action = action.to_s unless action.is_a? String
        user = current_user if user.blank?

        event = "gitlab.#{action}.#{target}".downcase
        event << ".#{detailed_event}" unless detailed_event.blank?

        ActiveSupport::Notifications.instrument event, {target: target, user: user, data: data}
      end
    end
  end
end

ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker.new)
