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
  end

  def watched_by?(user)
    Event::Subscription.by_user(user).by_target(self).by_action(:all).any?
  end

  def watch_status?(user)

  end

  def can_watch?(user)

  end
end
