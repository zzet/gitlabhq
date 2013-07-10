class Gitlab::Event::Builder::Project < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      5
    end

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
      meta = Gitlab::Event::Action.parse(action)
      target = source
      temp_data = data.attributes

      actions = []

      case source
      when ::Project
        case meta[:action]
        when :created
          actions << :created
        when :updated
          changes = source.changes

          if source.namespace_id_changed? && (source.namespace_id != changes[:namespace_id].first)
            actions << :transfer
            temp_data[:owner_changes] = changes
          end

          if project_changes_exists?(changes)
            temp_data[:previous_changes] = changes
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
          actions << :commented_commit if source.commit_id.present?
          actions << :commented_related if source.noteable.present? && source.commit_id.blank?
          actions << :commented if source.noteable.blank? && source.commit_id.blank?
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
          actions << :updated
        when :deleted
          actions << :reassigned
        end

      when ::UsersProject
        target = source.project

        case meta[:action]
        when :created
          actions << :joined
        when :updated
          actions << :updated
          changes = source.changes
          temp_data["previous_changes"] = changes
        when :deleted
          actions << :left
        end

      end

      events = []

      actions.each do |act|
        events << ::Event.new(action: act,
                              source: source, data: temp_data.to_json, author: user, target: target)
      end

      events
    end

    private

    def project_changes_exists?(changes)
      watched_fields = [:name, :path, :description,
                        :creator_id, :default_branch,
                        :issues_enabled, :wall_enabled,
                        :merge_requests_enabled, :public,
                        :issues_tracker, :issues_tracker_id]
      is_actual_changes = false
      watched_fields.each do |field|
        is_actual_changes = true if changes.keys.include? field.to_s
      end
      is_actual_changes
    end
  end
end
