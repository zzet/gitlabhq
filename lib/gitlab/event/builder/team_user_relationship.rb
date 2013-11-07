class Gitlab::Event::Builder::TeamUserRelationship < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      1
    end

    def can_build?(action, data)
      known_action = known_action? action, ::TeamUserRelationship.available_actions
      known_source = data.is_a? ::TeamUserRelationship
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
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