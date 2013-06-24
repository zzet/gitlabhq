class ::Gitlab::Event
  class << self

    def create_events(action, data)
      events = Gitlab::Event::Factory.build(action, data)
      events.each do |event|
        event.save
      end
    end

  end
end
