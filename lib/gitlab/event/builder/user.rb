class Gitlab::Event::Builder::User < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::User.available_actions
      known_sources = [::User, ::UserTeamUserRelationship, ::UsersProject, ::Key]
      known_source = known_sources.include? data.class
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      changes = source.changes
      temp_data = data.attributes

      actions = []

      case source
      when ::User
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

      when ::Key
        target = source.user

        case meta[:action]
        when :created
          actions << :added
        when :updated
          actions << :updated
        when :deleted
          actions << :deleted
        end
      when ::UsersProject
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
      when ::UserTeamUserRelationship
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

      p data

      actions.each do |act|
        events << ::Event.new(action: act,
                              source: source, data: temp_data.to_json, author: user, target: target)
      end

      events
    end
  end
end
