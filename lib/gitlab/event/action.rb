class Gitlab::Event::Action
  class << self
    def trigger(action, source, user = nil, data = nil, detailed_event = "")
      data = source if data.blank?
      source_name = source
      source_name = source.class.name.underscore unless source.is_a? String
      action = action.to_s unless action.is_a? String
      user = current_user if user.blank?

      event = "gitlab.#{action}.#{source_name}".downcase
      event << ".#{detailed_event}" if detailed_event.present?

      ActiveSupport::Notifications.instrument event, {source: source, user: user, data: data}
    end

    def current_user
      RequestStore.store[:current_user]
    end

    def parse(action)
      info = action.split "."
      info.shift # Shift "gitlab"
      {
        action: info.shift.to_sym,
        details: info
      }
    end
  end
end
