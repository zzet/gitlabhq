class Gitlab::Event::EventBuilder::Note < Gitlab::Event::EventBuilder::Base
  class << self
    def prioritet
      2
    end

    def can_build?(action, data)
      known_action = known_action? action, ::Note.available_actions
      known_source = known_source? data, ::Note.watched_sources
      known_source && known_action && data.commit_id.blank?
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
      meta[:action]
      target = source
      target = source.noteable if source.noteable.is_a? ::Note

      ::Event.new(action: meta[:action],
                  source: source, data: data.attributes, author: user, target: target)
    end
  end
end
