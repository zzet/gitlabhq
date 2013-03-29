class Gitlab::Event::Builder::UsersProject < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::UsersProject.available_actions
      known_source = known_source? data, ::UsersProject.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      temp_data = data.attributes
      actions = []
      target = source
      case meta[:action]
      when :created
        actions << :created
      when :updated
        temp_data["previous_changes"] = source.changes
        actions << :updated
      when :deleted
        actions << :deleted
      end

      ::Event.new(action: meta[:action],
                  source: source, data: temp_data, author: user, target: target)
    end
  end
end
