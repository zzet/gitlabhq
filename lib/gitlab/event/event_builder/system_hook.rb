class Gitlab::Event::EventBuilder::SystemHook < Gitlab::Event::EventBuilder::Base
  class << self
    def prioritet
      2
    end

    def can_build?(action, data)
      known_action = known_action? action, ::SystemHook.available_actions
      known_source = known_source? data, ::SystemHook.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
      meta[:action]
      target = source

      ::Event.new(action: meta[:action],
                  source: source, data: data.attributes, author: user, target: target)
    end
  end
end
