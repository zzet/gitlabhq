class Gitlab::Event::Builder::UserTeam < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      4
    end

    def can_build?(action, data)
      known_action = known_action? action, ::UserTeam.available_actions
      known_source = known_source? data, ::UserTeam.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
      temp_data = data.attributes
      actions = []

      case source.watchable_name
      when :user_team
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

      when :user_team_user_relationship
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

      when :user_team_project_relationship
        target = source.user_team

        case meta[:action]
        when :created
          actions << :assigned
        when :updated
          actions << :updated
          temp_data[:previous_changes] = source.changes
        when :deleted
          actions << :resigned
        end

      when :user_team_group_relationship
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

      end
      events = []
      actions.each do |act|
        events << ::Event.new(action: act,
                              source: source, data: temp_data, author: user, target: target)
      end
      events
    end
  end
end
