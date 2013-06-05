module Gitlab
  class Event::Factory

    class << self
      def build(action, data)
        events = []

        Gitlab::Event::Builder::Base.descendants.each do |descendant|
          events << descendant.build(action, data[:source], data[:user], data[:data]) if descendant.can_build?(action, data[:data])
        end

        events.flatten
      end

      def create_events(action, data)
        events = self.build(action, data)

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
end
