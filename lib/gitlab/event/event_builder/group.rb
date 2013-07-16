class Gitlab::Event::EventBuilder::Group < Gitlab::Event::EventBuilder::Base
  class << self
    def prioritet
      5
    end

    def can_build?(action, data)
      known_action = known_action? action, ::Group.available_actions
      known_source = known_source? data, ::Group.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
      target = source
      actions = []
      temp_data = data.attributes

      case source.watchable_name
      when :group

        case meta[:action]
        when :created
          actions << :created
        when :updated
          changes = source.changes

          actions << :transfer if source.owner_id_changed? && source.owner_id != changes[:owner_id].first

          if actions.blank?
            actions << :updated
            temp_data[:previous_changes] = changes
          end

        when :deleted
          actions << :deleted
        end

      when :project
        # TODO. refactoring
        if source.group.present?
          target = source.group

          case meta[:action]
          when :created
            actions << :added if source.group == target
          when :updated
            changes = source.changes

            # TODO. refactor
            actions << :added   if source.namespace_id_changed? && source.namespace_id != changes[:namespace_id].first && source.namespace == target
            actions << :removed if source.namespace_id_changed? && source.namespace_id != changes[:namespace_id].first && source.namespace != target #::Group.find_by_id(changes["namespace_id"]).present?
          when :deleted
            actions << :deleted
          end
        end

      when :user_team_group_relationship
        target = source.group

        case meta[:action]
        when :created
          actions << :assigned
        when :updated
          actions << :updated
          temp_data[:previous_changes] = source.changes
        when :deleted
          actions << :resigned
        end
      end

      events = []

      actions.each do |act|
        events << ::Event.new(action: act,
                              source_id: source.id, source_type: source.class.name,
                              target_id: target.id, target_type: target.class.name,
                              data: temp_data, author: user)
      end

      events
    end
  end
end
