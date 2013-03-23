class Gitlab::Event::Builder::Note < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::Note.available_actions
      known_source = known_source? data, ::Note.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      meta[:action]
      target = source
      target = source.noteable if source.noteable.is_a? ::Note

      ::Event.new(action: meta[:action],
                  source: source, data: data.attributes, author: user, target: target)
    end
  end
end
