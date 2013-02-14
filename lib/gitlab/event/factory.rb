module Gitlab
  class Event::Factory
    class << self
      def build(data)
        events = []

        Gitlab::Event::Builder::Base.descendants.each do |descendant|
          events << descendant.build(data) if descendant.can_build?(data)
        end

        events
      end

      def create_events(data)
        events = self.build(data)

        events.each do |event|
          event.save
        end
      end
    end
  end
end
