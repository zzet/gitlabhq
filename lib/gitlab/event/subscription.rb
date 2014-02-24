module Gitlab
  module Event
    class Subscription
      class << self
        # Subscribe user on target
        # Target - any watched sources, like as Project, Group, Team, User, MergeRequest
        # Options - any sources, watched by target, like as merge_request for Project
        def subscribe(user, target, options = [])
          if can_subscribe?(user, target)
            # target_id: target.id, target_type: target.class.name
            # instead
            # target: target
            # because Group < Namespace
            #         User < Namespace
            subscription = user.personal_subscriptions
                                .find_or_create_by(target_id: target.id, target_type: target.class.name)

            if subscription.persisted?
              options = target.class.watched_sources if options.blank?
              subscription.options = options
              subscription.save
            end

            subscription
          end
        end

        def update_subscription(subscription, options)
          target = subscription.target

          options = permitted_options(options, target.class)
          subscription.options = options
          subscription.save

          subscription
        end

        # Unsubscribe User from target
        def unsubscribe(user, target)
          user.personal_subscriptions.where(target_id: target.id, target_type: target.class).destroy_all
        end

        # Add auto_subscription for user
        # Based on this autosubscriptions user was subscribed on any sources
        #
        # Target: any source symbol, lake as :project, :group, :team
        # Namespace: for example target :project, namespace Group.instance
        #            added auto subscription for all new projects in Group.instance
        def create_auto_subscription(user, target, namespace = nil)
          if namespace
            if user.can?(:"read_#{namespace.class.name.underscore}", namespace)
              user.auto_subscriptions.create(target: target, namespace_id: namespace.id, namespace_type: namespace.class.name)
            end
          else
            user.auto_subscriptions.create(target: target)
          end
        end

        # Adjacent notifications now supported only for group
        # You subscribed on group
        # You want to receive notifications from all projects from this group
        def create_adjacent_subscriptions(event)
          source = event.source
          project = source.is_a?(Project) ? source : source.try(:project)
          if project
            if project.group && [:created, :transfered].include?(event.action.to_sym)
              adjacent_auto_subscriptions = ::Event::AutoSubscription.with_target(:project).with_namespace(project.group)
              adjacent_auto_subscriptions.find_each do |aas|
                if aas.user.can?(:"read_#{aas.namespace.class.name.underscore}", aas.namespace)
                  Rails.logger.info "Create subscription by action: " << name
                  Gitlab::Event::Subscription.subscribe(aas.user, project)
                end
              end
            end
          end
        end

        def subscribe_to_all(user, type)
          type = type.capitalize
          options = type.capitalize.constantize.watched_sources

          case type
            when 'Project'
              targets = user.known_projects
            when 'Team'
              targets = user.known_teams
            when 'Group'
              targets = user.authorized_groups
            when 'User'
              targets = User.active
            else
              return []
          end

          existing_ids = user.personal_subscriptions.where(target_type: type).pluck(:target_id)
          ids = targets.pluck(:id)

          to_create_ids = ids - existing_ids
          subscriptions = []

          to_create_ids.each do |target_id|
            subscriptions << ::Event::Subscription.new(
              user_id: user.id,
              target_id: target_id,
              target_type: type,
              options: options
            )
          end

          #NOTE hack for speed
          ::Event::Subscription.import(subscriptions, validate: false)
        end

        private

        def can_subscribe?(user, target)
          access = :"read_#{target.class.name.underscore}"
          user.can?(access, target)
        end

        def permitted_options(options, model)
          options = model.watched_sources.map(&:to_s) & options
          options.map(&:to_sym)
        end
      end
    end
  end
end
