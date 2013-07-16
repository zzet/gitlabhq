class Gitlab::Event::Factory

  class << self
    def build(action, data)
      events = []

      ::Gitlab::Event::EventBuilder::Base.descendants.each do |descendant|
        events << descendant.build(action, data[:source], data[:user], data[:data]) if descendant.can_build?(action, data[:data])
      end

      events.flatten
    end

  end
end
