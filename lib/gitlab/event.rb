class ::Gitlab::Event
  class << self

    def create_events(action, data)
      events = Gitlab::Event::Factory.build(action, data)

      if events.any?
        parent_event = Gitlab::Event::Builder::Base.find_parent_event(action, data)

        if parent_event.blank?
          events.each_with_index do |e, i|
            if e.source == e.target
              e.save
              events.delete_at(i)
            end
          end
          parent_event = Gitlab::Event::Builder::Base.find_parent_event(action, data)
        end

        events.each do |event|
          event.parent_event = parent_event if parent_event.present?
          event.save
        end
      end
    end

  end
end
