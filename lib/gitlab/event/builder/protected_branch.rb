class Gitlab::Event::Builder::ProtectedBranch < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      2
    end

    def can_build?(action, data)
      known_action = known_action? action, ::ProtectedBranch.available_actions
      known_source = known_source? data, ::ProtectedBranch.watched_sources
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
