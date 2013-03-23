module Watchable
  extend ActiveSupport::Concern

  module ClassMethods
    def actions_to_watch(actions)
      return if actions.empty?

      @actions ||= actions.select { |action| Event::Action.action_exists?(action) }
    end

    def available_actions
      @actions
    end

    def actions_sources(entities)
      return if entities.empty?

      @entities ||= entities.select { |entity| defined?(entity.to_s.camelize.constantize) }
    end

    def watched_sources
      @entities
    end

    def watchable_name
      self.name.underscore.to_sym
    end
  end

  def watchable_name
    self.class.name.underscore.to_sym
  end

  def watched_by?(user)
    Event::Subscription.by_user(user).by_target(self).by_action(:all).any?
  end

  def watch_status?(user)

  end

  def can_watch?(user)

  end
end
