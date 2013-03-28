class Gitlab::Event::Builder::Project < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::Project.available_actions
      known_source = known_source? data, ::Project.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      target = source
      temp_data = data.attributes

      actions = []

      case source.watchable_name
      when :project
        case meta[:action]
        when :created
          actions << :created
        when :updated
          changes = source.changes

          actions << :transfer if source.creator_id_changed? && source.creator_id != changes[:creator_id].first
          if actions.blank?
            temp_data[:previous_changes] = changes
            actions << :updated
          end
        when :deleted
          actions << :deleted
        end
      when :issue
        target = source.project

        case meta[:action]
        when :created
          actions << :opened
        when :updated
          # Any changes?
        when :closed
          actions << :closed
        when :reopened
          actions << :reopened
        when :deleted
          actions << :deleted
        end

      when :milestone
        target = source.project

        case meta[:action]
        when :created
          actions << :created
        when :closed
          actions << :closed
        end

      when :note
        target = source.project

        case meta[:action]
        when :created
          actions << :commented_related if source.noteable.present?
          actions << :commented if source.noteable.blank?
        end

      when :merge_request
        target = source.project

        case meta[:action]
        when :created
          actions << :opened
        when :updated
          # Any changes?
          # For example if code base is updated?
        when :closed
          actions << :closed
        when :reopened
          actions << :reopened
        when :merged
          actions << :merged
        end

      when :snippet
        target = source.project

        case meta[:action]
        when :created
          actions << :created
        when :updated
          actions << :updated
        when :deleted
          actions << :deleted
        end

      when :project_hook
        target = source.project

        case meta[:action]
        when :created
          actions << :added
        when :updated
          actions << :updated
        when :deleted
          actions << :deleted
        end

      when :protected_branch
        target = source.project

        case meta[:action]
        when :created
          actions << :created
        when :updated
        when :deleted
          actions << :deleted
        end

      when :service
        target = source.project

        case meta[:action]
        when :created
          actions << :added
        when :updated
          actions << :updated
        when :deleted
          actions << :deleted
        end

      when :user_team_project_relationship
        target = source.project

        case meta[:action]
        when :created
          actions << :assigned
        when :updated
          actions << :updated
        when :deleted
          actions << :deleted
        end

      when :users_project
        target = source.project

        case meta[:action]
        when :created
          actions << :joined
        when :updated
          actions << :updated
        when :deleted
          actions << :left
        end

      when :push
        target = source.project

        case meta[:action]
        when :created
          actions << :created_branch  if source.created_branch?
          actions << :deleted_branch  if source.deleted_branch?
          actions << :created_tag     if source.created_tag?
          actions << :deleted_tag     if source.deleted_tag?

          actions << :pushed
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
