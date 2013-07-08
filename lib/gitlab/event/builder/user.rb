class Gitlab::Event::Builder::User < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      6
    end

    def can_build?(action, data)
      known_action = known_action? action, ::User.available_actions
      known_source = known_source? data, ::User.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
      changes = source.changes
      temp_data = data.attributes

      actions = []

      case source.watchable_name
      when :user
        target = source

        case meta[:action]
        when :created
          actions << :created
        when :updated
          actions << :updated
          temp_data["previous_changes"] = changes
        when :deleted
          actions << :deleted
        end

      when :key
        target = source.user

        case meta[:action]
        when :created
          actions << :added
        when :updated
          actions << :updated
        when :deleted
          actions << :deleted
        end
      when :users_project
        target = source.user

        case meta[:action]
        when :created
          actions << :joined
        when :updated
          actions << :updated
          temp_data["previous_changes"] = changes
        when :deleted
          actions << :left
        end
      when :user_team_user_relationship
        target = source.user

        case meta[:action]
        when :created
          actions << :joined
        when :updated
          actions << :updated
          temp_data["previous_changes"] = changes
        when :deleted
          actions << :left
        end
        # TODO.
        # Add support with Issue, MergeRequest, Milestone, Note, ProjectHook, ProtectedBranch, Service, Snippet
        # All models, which contain User
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
