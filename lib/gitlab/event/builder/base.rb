class Gitlab::Event::Builder::Base

  class << self
    def descendants
      # In production class cache :)
      Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| load f} if super.blank?

      super.sort {|x,y| x.prioritet <=> y.prioritet}
    end

    def can_build?(action, data)
      raise NotImplementedError
    end

    def build(action, target, user, data)
      raise NotImplementedError
    end

    def prioritet
      raise NotImplementedError
    end

    def known_action?(action, available_actions)
      meta = Gitlab::Event::Action.parse(action)
      available_actions.include? meta[:action]
    end

    def find_parent_event(action, data)
      collector = EventHierarchyWorker.collector
      parent_event = collector.events.parent(action, data)

      if parent_event.present?
        event_info = parent_event[:data]
        action_meta = Gitlab::Event::Action.parse(parent_event[:name])
        source = event_info[:source] if event_info[:source].present?
        user = event_info[:user] if event_info[:user].present?

        level = 0

        if source.present? && user.present? && source.respond_to?(:id)
          candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                   target_id: source.try(:id), target_type: source.class.name,
                                   author_id: user.id, action: action_meta[:action])

          if candidates.blank? && (source.is_a?(::Project) && action_meta[:action] == "updated")
            candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                     target_id: source.try(:id), target_type: source.class.name,
                                     author_id: user.id, action: :transfer)
          end

          level = 1

          if candidates.blank?
            candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                     author_id: user.id, action: action_meta[:action])
            level = 2
            if candidates.blank?
              candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                       target_id: source.try(:id), target_type: source.class.name,
                                       author_id: user.id).
                                       where("action not in (?)", [:created, :updated, :deleted])
              level = 3
            end
          end

          candidate = candidates.last

          return nil if candidate && candidate.notifications.where(notification_state: [:delivered, :new]).any?
          return candidate.parent_event if candidate && candidate.parent_event.present? && level > 1
          return candidate
        end
      end
      nil
    end
  end
end
