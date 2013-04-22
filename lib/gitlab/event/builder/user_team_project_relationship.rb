class Gitlab::Event::Builder::UserTeamProjectRelationship < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::UserTeamProjectRelationship.available_actions
      known_source = data.is_a? ::UserTeamProjectRelationship
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      actions = []
      target = source
      actions << meta[:action]
      case meta[:action]
      when :created
      when :updated
      when :deleted
      end

      ::Event.new(action: meta[:action], source: source, data: data.to_json, author: user, target: target)
    end
  end
end
