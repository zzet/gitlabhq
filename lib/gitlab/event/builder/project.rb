class Gitlab::Event::Builder::Project < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::Project.available_actions
      known_sources = [::Project,
                       ::Issue, ::Milestone, ::Note, ::MergeRequest, ::Snippet,
                       ::ProjectHook, ::ProtectedBranch, ::Service,
                       ::UserTeamProjectRelationship, ::UsersProject]
      known_source = known_sources.include? data.class
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      target = source

      actions = []

      case source
      when ::Project
        case meta[:action]
        when :created
          actions << :created
        when :updated
          changes = source.changes

          actions << :transfer if source.creator_id_changed? && source.creator_id != changes[:creator_id].first
          if actions.blank?
            data[:changes] = changes
            actions << :updated
          end
        when :deleted
          actions << :deleted
        end
      when ::Issue
        target = source.project

        case meta[:action]
        when :created
          actions << :opened
        when :updated
          # Any changes?
        when :closed
          actions << meta[:action]
        when :reopened
          actions << meta[:action]
        when :deleted
          actions << meta[:action]
        end

      when ::Milestone
        target = source.project

        case meta[:action]
        when :created
          actions << meta[:action]
        when :closed
          actions << meta[:action]
        end

      when ::Note
        target = source.project

        case meta[:action]
        when :created
          actions << :commented_related if source.noteable.present?
          actions << :commented if source.noteable.blank?
        end

      when ::MergeRequest
        target = source.project

        case meta[:action]
        when :created
          actions << :opened
        when :updated
          # Any changes?
          # For example if code base is updated?
        when :closed
          actions << meta[:action]
        when :reopened
          actions << meta[:action]
        when :merged
          actions << meta[:action]
        end

      when ::Snippet
        target = source.project

        case meta[:action]
        when :created
          actions << meta[:action]
        when :updated
          actions << meta[:action]
        when :deleted
          actions << meta[:action]
        end

      when ::ProjectHook
        target = source.project

        case meta[:action]
        when :created
          actions << :added
        when :updated
          actions << meta[:action]
        when :deleted
          actions << meta[:action]
        end

      when ::ProtectedBranch
        target = source.project

        case meta[:action]
        when :created
          actions << :created
        when :updated
        when :deleted
          actions << :deleted
        end

      when ::Service
        target = source.project

        case meta[:action]
        when :created
          actions << :added
        when :updated
          actions << meta[:action]
        when :deleted
          actions << meta[:action]
        end

      when ::UserTeamProjectRelationship
        target = source.project

        case meta[:action]
        when :created
          actions << :assigned
        when :updated
          actions << meta[:action]
        when :deleted
          actions << meta[:action]
        end

      when ::UsersProject
        target = source.project

        case meta[:action]
        when :created
          actions << :joined
        when :updated
          actions << meta[:action]
        when :deleted
          actions << :left
        end

      end

      events = []

      actions.each do |act|
        events << ::Event.new(action: act,
                              source: source, data: data.to_json, author: user, target: target)
      end

      events
    end
  end
end
