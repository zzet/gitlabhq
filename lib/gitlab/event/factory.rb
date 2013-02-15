module Gitlab
  class Event::Factory
    class << self
      def build(action, data)
        events = []

        Gitlab::Event::Builder::Base.descendants.each do |descendant|
          events << descendant.build(action, data) if descendant.can_build?(action, data)
        end

        events
      end

      def create_events(action, data)
        events = self.build(action, data)

        events.each do |event|
          event.save
        end
      end
    end
  end
end
