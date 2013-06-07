class Gitlab::Event::Builder::Base

  class << self
    def descendants
      # In production class cache :)
      Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| load f} if super.blank?

      super
    end

    def can_build?(action, data)
      raise NotImplementedError
    end

    def build(action, target, user, data)
      raise NotImplementedError
    end

    def known_action?(action, available_actions)
      meta = parse_action(action)
      available_actions.include? meta[:action]
    end

    def find_parent_event(action, data)
      collector = EventHierarchyWorker.collector
      parent_event = collector.events.parent(action, data)

      if parent_event.present?
        event_info = parent_event[:data]
        action_meta = parse_action(parent_event[:name])
        source = event_info[:source] if event_info[:source].present?
        user = event_info[:user] if event_info[:user].present?

        if source.present? && user.present?
          candidates = Event.where(source_id: source.id, source_type: source.class.name,
                                   target_id: source.id, target_type: source.class.name,
                                   author_id: user.id, action: action_meta[:action])

          if candidates.blank?
            candidates = Event.where(source_id: source.id, source_type: source.class.name,
                                     author_id: user.id, action: action_meta[:action])
            if candidates.blank?
              candidates = Event.where(source_id: source.id, source_type: source.class.name,
                                       target_id: source.id, target_type: source.class.name,
                                       author_id: user.id).
                                       where("action not in (?)", [:created, :updated, :deleted])
            end
          end

          candidate = candidates.last

          return nil if candidate && candidate.notifications.where(notification_state: :delivered).any?
          return candidate
        end
      end
      nil
    end

    private

    def parse_action(action)
      info = action.split "."
      info.shift # Shift "gitlab"
      {
        action: info.shift.to_sym,
        details: info
      }
    end
  end
end
