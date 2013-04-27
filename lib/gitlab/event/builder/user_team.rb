class Gitlab::Event::Builder::UserTeam < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::UserTeam.available_actions
      known_sources = [::UserTeam, ::UserTeamProjectRelationship, ::UserTeamUserRelationship]
      known_source = known_sources.include? data.class
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      temp_data = data.attributes
      actions = []

      case source
      when ::UserTeam
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

      when ::UserTeamUserRelationship
        target = source.user_team

        case meta[:action]
        when :created
          actions << :joined
        when :updated
          actions << :updated
          temp_data[:previous_changes] = source.changes
        when :deleted
          actions << :left
        end

      when ::UserTeamProjectRelationship
        target = source.user_team

        case meta[:action]
        when :created
          actions << :assigned
        when :updated
          actions << :updated
          temp_data[:previous_changes] = source.changes
        when :deleted
          actions << :reassigned
        end

      end
      events = []
      actions.each do |act|
        events << ::Event.new(action: act,
                              source: source, data: temp_data.to_json, author: user, target: target)
      end
      events
    end
  end
end
