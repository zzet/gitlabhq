module Gitlab
  module Event
    class Acion
      cattr_accessor :current_user

      class << self

        def trigger(action, source, user = nil, data = nil, detailed_event = "")
          data = source if data.blank?
          source_name = source.class.name unless source.is_a? String
          action = action.to_s unless action.is_a? String
          user = current_user if user.blank?

          event = "gitlab.#{action}.#{source_name}".downcase
          event << ".#{detailed_event}" unless detailed_event.blank?

          ActiveSupport::Notifications.instrument event, {source: source, user: user, data: data}
        end

      end

    end
  end
end


ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker.new)
