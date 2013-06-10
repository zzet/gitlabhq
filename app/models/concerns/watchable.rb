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

    def adjacent_targets(adjacents)
      return if adjacents.empty?

      @adjacent_targets ||= adjacents.select { |adjacent| defined?(adjacent.to_s.camelize.constantize) }
      fill_adjacent_sources(@adjacent_targets)
    end

    def watched_adjacent_targets
      @adjacent_targets
    end

    def adjacent_sources(adjacents)
      return if adjacents.empty?

      @adjacent_sources ||= adjacents.select { |adjacent| defined?(adjacent.to_s.camelize.constantize) }
    end

    def watched_adjacent_sources
      @adjacent_sources ||= []
    end

    protected

    def fill_adjacent_sources(targets)
      targets.each do |target|
        target.to_s.camelize.constantize.add_to_adjacent_sources(self.name.downcase.to_sym)
      end
    end

    def add_to_adjacent_sources(source)
      @adjacent_sources << source if !watched_adjacent_sources.include?(source)
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
