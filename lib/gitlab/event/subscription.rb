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
          target = target.to_sym if target.is_a? String

          if target && (target.is_a?(Symbol) || target.is_a?(Class))
            subscribe_on_target_category(user, target, action, source)
          else
            new_source = source.to_s.camelize.constantize if source.is_a?(Symbol) && source != :all
            target = new_source if target.blank?

            subscribe!(user, action, target, source) if can_subscribe?(user, action, target, source)
          end
        end

        # Find by target subscriptions
        # Subscribe on target
        # TODO. If user removed from Team or Project or Group - remove subscriptions
        def create_subscriprions_by_target(external_source)
          target_category = external_source.class.name.underscore.to_sym
          typed_subscriptions = ::Event::Subscription.by_target_category(target_category)
          typed_subscriptions.each do |subscription|
            user = subscription.user
            action = subscription.action
            target = external_source
            source = subscription.source
            subscribe!(user, action, target, source) if can_subscribe?(user, action, target, source)
          end
        end

        # target = event target
        # Expected Symbol || Class_name
        def subscribe_on_target_category(user, target, action = :all, source = :all)
          target = target.to_s.underscore.to_sym if target.is_a? Class
          target = target.to_sym if target.is_a? String

          subscribe!(user, action, target, source)
        end

        def unsubscribe(user, action, target, source)
          target = target.to_sym if target.is_a? String

          new_source = source.to_s.camelize.constantize if source.is_a?(Symbol) && !([:all, :new].include?(source))

          target = new_source if target.blank?

          unsubscribe!(user, action, target, source)
        end


        def can_subscribe?(user, action, target, source)
          subscriptions = []

          Gitlab::Event::Subscriptions::Base.descendants.each do |descendant|
            subscriptions << descendant.can_subscribe?(user, action, target, source)
          end

          return subscriptions.inject { |c, s| c = c || s }
        end

        protected

        def subscribe!(user, action, target, source)
          subscription = nil

          subscription_params = { user: user, action: action }
          if target
            if target.is_a? Symbol
              subscription_params[:target_category] = target
            else
              if target.persisted?
                subscription_params[:target_id] = target.id
                subscription_params[:target_type] = target.class.name
              end
            end

            case source
              # User subscribe on source type by target
            when Symbol
              subscription_params[:source_category] = source.downcase
            when Class
              # Subscribe by class name?
              source_category = source.name.downcase.to_sym
              subscription_params[:source_category] = source_category
            else
              # subscribe on current source updation
              # For example if user commented Issue
              if source.persisted?
                subscription_params[:source_id] = source.id
                subscription_params[:source_type] = source.class.name
              end
            end

            # Check, if user have some similar subscription
            subscription = ::Event::Subscription.new(subscription_params)
            subscription.save unless exist_similar_subscription?(subscription)
          end
        end

        def unsubscribe!(user, action, target, source)
          subscription = nil
          if target.is_a? Symbol
            subscription = ::Event::Subscription.by_user(user).by_target_category(target).by_action(action)
          else
            subscription = ::Event::Subscription.by_user(user).by_target(target).by_source_type(source).by_action(action)
          end
          if subscription.any?
            subscription.each do |sbs|
              sbs.destroy
            end
          end
        end

        def exist_similar_subscription?(subscription)
          user_exist_subscriptions = ::Event::Subscription.by_user(subscription.user)
          return false if user_exist_subscriptions.blank?

          if subscription.target_category
            targeted_by_category_subscriptions = user_exist_subscriptions.by_target_category(subscription.target_category)
            return false if targeted_by_category_subscriptions.blank?
          else
            targeted_subscriptions = user_exist_subscriptions.by_target(subscription.target)
            return false if targeted_subscriptions.blank?
          end

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
