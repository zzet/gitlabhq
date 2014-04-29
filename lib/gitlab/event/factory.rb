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

    def create_events(action, data)
      events = Gitlab::Event::Builder.build(action, data)

      if events.any?
        parent_event = Gitlab::Event::Builder.find_parent_event(action, data)

        if parent_event.blank?
          events.select { |e| e.source == e.target }.each(&:save)
          parent_event = Gitlab::Event::Builder.find_parent_event(action, data)
        end

        events.each do |event|
          event.parent_event = parent_event if parent_event.present? && (event != parent_event)
          event.save
        end

        if parent_event.try(:source).try(:relation_table?)
          relations = parent_event.source.relations
          parent_event.first_domain_id = relations.first.id
          parent_event.first_domain_type = relations.first.class.name

          parent_event.second_domain_id = relations.second.id
          parent_event.second_domain_type = relations.second.class.name

          parent_event.save
        end
      end
    end
  end
end
