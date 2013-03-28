class Gitlab::Event::Builder::Push < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::Push.available_actions
      known_source = known_source? data, ::Push.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      actions = []

      target = source
      push_data = data[:push_data]

      case meta[:action]
      when :pushed
        actions << :created_branch  if source.created_branch?
        actions << :deleted_branch  if source.deleted_branch?
        actions << :created_tag     if source.created_tag?
        actions << :deleted_tag     if source.deleted_tag?

        actions << :pushed          #if actions.blank?
      end

      events = []

      actions.each do |act|
        events << ::Event.new(action: act, source_type: source, data: push_data, author: user, target: target)
      end

      events

    end
  end
end
