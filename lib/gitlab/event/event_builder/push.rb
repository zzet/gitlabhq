class Gitlab::Event::EventBuilder::Push < Gitlab::Event::EventBuilder::Base
  class << self
    def prioritet
      2
    end

    def can_build?(action, data)
      known_action = known_action? action, [:pushed]
      known_source = known_source? data, ::Push.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = Gitlab::Event::Action.parse(action)
      actions = []

      target    = source.project
      user      = source.user
      temp_data = source.attributes

      case meta[:action]
      when :pushed
        if source.refs_action?
          actions << :created_branch  if source.created_branch?
          actions << :deleted_branch  if source.deleted_branch?
          actions << :created_tag     if source.created_tag?
          actions << :deleted_tag     if source.deleted_tag?
        end

        actions << :pushed          if actions.blank?
      end

      events = []

      actions.each do |act|
        events << ::Event.new(action: act, source: source, data: temp_data, author: user, target: target)
      end

      events

    end
  end
end
