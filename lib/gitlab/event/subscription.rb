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
        def subscribe(user, action, target, source)
          new_source = source.to_s.camelize.constantize if source.is_a?(Symbol) && source != :all
          target = new_source if target.blank?

          subscribe!(user, action, target, source) if can_subscribe?(user, action, target, source)
        end

        def unsubscribe(user, action, target, source)
          new_source = source.to_s.camelize.constantize if source.is_a?(Symbol) && source != :all
          target = new_source if target.blank?

          unsubscribe!(user, action, target, source)
        end


        def can_subscribe?(user, action, target, source)
          action = ::Event::Action.action_by_name(action) if action.is_a? Symbol

          subscriptions = []

          Gitlab::Event::Subscriptions::Base.descendants.each do |descendant|
            subscriptions << descendant.can_subscribe?(user, action, target, source)
          end

          return subscriptions.inject { |c, s| c = c || s }
        end

        def subscribe!(user, action, target, source)
          action = ::Event::Action.action_by_name(action)
          subscription = nil

          if target && target.persisted?

            subscription_params = { user: user, action: action, target: target }

            case source
              # User subscribe on source type by target
            when Symbol
              subscription_params[:source_category] = source.downcase
            else
              if source.persisted?
                # subscribe on current source updation
                # For example if user commented Issue
                subscription_params[:source] = source
              else
                # Subscribe by class name?
                source_category = source.name.downcase.to_sym
                subscription_params[:source_category] = source_category
              end
            end

            # Check, if user have some similar subscription
            subscription = ::Event::Subscription.new(subscription_params)
            p exist_similar_subscription?(subscription)
            subscription.save unless exist_similar_subscription?(subscription)
            p subscription.errors unless subscription.errors.blank?
          end
        end

        def unsubscribe!(user, action, target, source)
          subscription = ::Event::Subscription.by_user(user).by_target(target).by_source_type(source).by_action(action)
          if subscription.any?
            subscription.each do |sbs|
              sbs.destroy
            end
          end
        end

        def exist_similar_subscription?(subscription)
          user_exist_subscriptions = ::Event::Subscription.by_user(subscription.user)
          return false if user_exist_subscriptions.blank?

          targeted_subscriptions = user_exist_subscriptions.by_target(subscription.target)
          return false if targeted_subscriptions.blank?

          source = subscription.source.blank? ? subscription.source_type : subscription.source
          sourcesed_subscriptions = targeted_subscriptions.by_source_type(source)
          return false if sourcesed_subscriptions.blank?

          if subscription.source.blank?
            sourced_subscriptions = targeted_subscriptions.with_source
            if sourced_subscriptions.count == sourcesed_subscriptions.count
              # We will subscribe on source type, but have some current subscriptions
              # I will subscribe on all events
              return false
            else
              # We have some typed subscription
              actioned_subscriptions = sourced_subscriptions.by_action(action).any?
              return true if actioned_subscriptions.any?
              return false
            end
          else
            sourced_subscriptions = targeted_subscriptions.without_source
            if sourced_subscriptions.count == sourcesed_subscriptions.count?
              # We have subscriptions by type, but wants to subscribe on current event
              # I will subscribe, to save all user subscriptions
              return false
            else
              # We have some typed subscription
              actioned_subscriptions = sourced_subscriptions.by_action(action).any?
              return true if actioned_subscriptions.any?
              return false
            end
          end
        end
      end
    end
  end
end
