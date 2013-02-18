module Gitlab
  module Event
    class Subscription
      class << self
        #
        # User can subscribe on:
        # - Event Source changes
        # - Event Source changes, which associated with target
        # - Event category (Source by type) changes
        # - Event category (Source by type) changes which associated with target
        #
        def subscribe(user, action, source, target)
          new_source = source.to_s.capitalize.constantize if source.is_a? Symbol
          target = new_source if target.blank?

          subscriber = "Gitlab::Event::Subscriptions::#{target.class}".constantize
          subscriber.subscribe(user, asction, source, target)
        end

        def available(user, source)
          subscriptions = []

          if source.nil?
            Gitlab::Event::Subscriptions::Base.descendants.each do |descendant|
              subscriptions << descendant.available(user)
            end
          else
            Gitlab::Event::Subscriptions::Base.descendants.each do |descendant|
              subscriptions << descendant.available(user, source)
            end
          end
          subscriptions.flatten
        end
      end
    end
  end
end
