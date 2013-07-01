class Gitlab::Event::Builder::UserTeamUserRelationship < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      0
    end

    def can_build?(action, data)
      known_action = known_action? action, ::UserTeamUserRelationship.available_actions
      known_source = data.is_a? ::UserTeamUserRelationship
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
        actions << :updated
        temp_data[:previous_changes] = source.changes
      when :deleted
        actions << :deleted
      end

      ::Event.new(action: meta[:action],
                  source: source, data: temp_data.to_json, author: user, target: target)
    end
  end
end
