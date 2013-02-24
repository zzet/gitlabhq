module Gitlab
  class Event::Factory
    class << self
      def build(action, data)
        events = []

        Gitlab::Event::Builder::Base.descendants.each do |descendant|
          events << descendant.build(action, data[:source], data[:user], data[:data]) if descendant.can_build?(action, data[:data])
        end

        #p events
        events.flatten
      end

      def create_events(action, data)
        events = self.build(action, data)

        events.each do |event|
          event.save
          # TODO. Remove debug
          p event.errors if event.errors.present? && !event.source.is_a?(::User)
        end
      end
    end
  end
end
