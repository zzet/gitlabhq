class Gitlab::Event::Builder::UsersProject < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::UsersProject.available_actions
      known_source = data.is_a? ::UsersProject
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      actions = []
      target = source
      case meta[:action]
      when :created
        actions << :created
      when :updated
        data[:changes] = source.changes
        actions << :updated
      when :deleted
        actions << :deleted
      end

      ::Event.new(action: meta[:action],
                  source: source, data: data.to_json, author: user, target: target)
    end
  end
end
