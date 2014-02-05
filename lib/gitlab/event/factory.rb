class Gitlab::Event::Factory
  class << self

    # Create events for action
    #
    # Base event for source (source == target)
    # Related events for source ( source != target)
    def call(name, started, finished, unique_id, data)
      Rails.logger.info "Triggered action: " << name
      Rails.logger.info "Uniq id is: " << unique_id

      create_events(name, data)
    end

    def build(action, data)
      events = []

      events = Gitlab::Event::Builder.build(action, data)

      events.flatten
    end

    def create_events(action, data)
      events = self.build(action, data)

      if events.any?
        parent_event = Gitlab::Event::Builder.find_parent_event(action, data)

        if parent_event.blank?
          events.each_with_index do |e, i|
            if e.source == e.target
              e.save
            end
          end
          parent_event = Gitlab::Event::Builder.find_parent_event(action, data)
        end

        events.each do |event|
          event.parent_event = parent_event if parent_event.present? && (event != parent_event)
          event.save
        end
      end
    end
  end
end
