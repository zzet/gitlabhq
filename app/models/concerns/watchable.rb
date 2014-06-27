module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :events,         as: :source
    has_many :related_events, as: :target, class_name: Event
    has_many :subscriptions,  as: :target, class_name: Event::Subscription
    has_many :notifications,  through: :subscriptions
    has_many :subscribers,    through: :subscriptions
  end

  module ClassMethods
    attr_reader :watched_titles, :watched_descriptions

    # Main DSL method for watch description
    def watch(&block)
      instance_eval(&block)
      add_watch_callbacks
    end

    def title(title)
      @watched_titles ||= {}
      @watched_titles[@watched_sources.last] = title
    end

    def description(description)
      @watched_descriptions ||= {}
      @watched_descriptions[@watched_sources.last] = description
    end

    # Related entity, source of action
    def source(source_name, &block)
      @watched_sources ||= []
      @watched_sources << source_name unless @watched_sources.include?(source_name)
      watch_for(source_name)
      instance_eval(&block)
    end

    # Actions, which must be executed befor event process
    def before(options = {})
      @before_actions ||= {}
      @before_actions[@watched_sources.last] = { actions: [], conditions: [] }

      @before_actions[@watched_sources.last][:actions]     = (options[:do].present?         ? [options[:do]].flatten          : [])
      @before_actions[@watched_sources.last][:conditions]  = (options[:conditions].present? ? [options[:conditions]].flatten  : [])
    end

    # Original or system action
    #
    # Can be transformed to another action for human
    def from(original_action, options = {}, &block)
      return if options.empty?
      @watched_actions ||= []
      @watched_actions << original_action unless @watched_actions.include?(original_action)
      @watched_actions_map ||= {}
      @watched_actions_map[@watched_sources.last] ||= {}
      @watched_actions_map[@watched_sources.last][original_action] ||= []
      action_map = { name: options[:to] }
      action_map[:conditions] = []
      unless options[:conditions].nil?
        if options[:conditions].respond_to?(:each)
          options[:conditions].each do |condition|
            action_map[:conditions] << condition
          end
        else
          action_map[:conditions] << options[:conditions]
        end
      else
        action_map[:conditions] << { if: true }
      end
      action_map[:yield] = block_given? ? block : -> { }
      @watched_actions_map[@watched_sources.last][original_action] << action_map
    end

    # Base actions for model
    #
    # Base actions can be triggered via ActiveSupport::Notifications
    def base_actions
      @base_actions ||= @watched_actions_map[watchable_name].keys
    end

    def result_actions_names(source = watchable_name)
      @watched_actions_map[source].map do |k, v|
        v.map { |a| a[:name] }
      end.flatten
    end

    # Before actions for current target
    def before_actions_for(target)
      @before_actions[target] || { actions: [], conditions: [] }
    end

    # All uniq base actions from watched sources
    def watched_actions
      @watched_actions
    end

    # All sources to watch
    def watched_sources
      @watched_sources
    end

    # Fill sources, wich watch for current entity
    def watched_by(watcher = nil)
      return @watched_by if watcher.nil?

      @watched_by ||= []
      @watched_by << watcher
    end

    def watch_for(source)
      source.to_s.camelize.constantize.watched_by(self.name.underscore.to_sym)
    end

    def matrix_for(source = watchable_name, action = nil)
      matrix_for_source = @watched_actions_map[source]
      if matrix_for_source
        if action
          matrix_for_source[action]
        else
          matrix_for_source
        end
      else
        []
      end
    end

    def watchable_name
      self.name.underscore.to_sym
    end

    def add_watch_callbacks
      matrix_for(watchable_name).keys.uniq.each do |action|
        if self.respond_to?(action)
          class_eval <<-end_eval, __FILE__, __LINE__ + 1
          def trigger_#{action}_event_notification(*args)
            Gitlab::Event::Action.trigger :#{action}, self
          end

          if action == :destroy
            before_#{action} :trigger_#{action}_event_notification, prepend: true if respond_to?(:before_#{action})
          else
            after_#{action} :trigger_#{action}_event_notification, prepend: true if respond_to?(:after_#{action})
          end

          if respond_to?(:before_#{action}) && respond_to?(:after_#{action})
            before_#{action} :before_#{action}_event_border, prepend: true
            after_#{action}  :after_#{action}_event_border, prepend: true

            def before_#{action}_event_border
              RequestStore.store[:borders] ||= []
              RequestStore.store[:borders].push("gitlab.#{action}.#{self.name.underscore}")
            end

            def after_#{action}_event_border
              RequestStore.store[:borders] ||= []
              RequestStore.store[:borders].pop
            end
          end
          end_eval
        else
          if self.respond_to?(:state_machines)
            self.state_machines.each do |arr|
              arr.each do |sm|
                if sm.is_a? StateMachine::Machine
                  if sm.events.map {|e| e.name }.include?(action)
                    WatchableObserver.send :define_method, :"before_#{action}" do |model, transition|
                      RequestStore.store[:borders] ||= []
                      RequestStore.store[:borders].push("gitlab.#{transition.event}.#{model.class.name.underscore}")
                    end unless WatchableObserver.respond_to?("before_#{action}")

                    WatchableObserver.send :define_method, :"after_#{action}" do |model, transition|
                      Gitlab::Event::Action.trigger :"#{transition.event}", model
                      RequestStore.store[:borders] ||= []
                      RequestStore.store[:borders].pop
                    end unless WatchableObserver.respond_to?("after_#{action}")

                    WatchableObserver.send :define_method, :after_failure_to_transition do |model, transition|
                      Rails.logger.info "gitlab.#{transition.event}.#{model.class.name} fail"
                      RequestStore.store[:borders].pop if RequestStore.store[:borders].present?
                    end unless WatchableObserver.respond_to?(:after_failure_to_transition)
                  end
                end
              end
            end
          end
        end
      end
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
        target.to_s.camelize.constantize.add_to_adjacent_sources(self.name.underscore.to_sym)
      end
    end

    def add_to_adjacent_sources(source)
      @adjacent_sources << source if !watched_adjacent_sources.include?(source)
    end

  end

  def watched_by?(user)
    Event::Subscription.by_user(user).by_target(self).any?
  end

  def watch_status?(user)

  end

  def can_watch?(user)

  end
end
