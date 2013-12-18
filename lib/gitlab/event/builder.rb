class Gitlab::Event::Builder
  class << self
    def build(event_action, data)
      meta = Gitlab::Event::Action.parse(event_action)

      @source  = data[:source]
      @changes = (meta[:action] == :update ? @source.changes : nil)

      source_class = @source.class
      source_key = meta[:source]

      @events = []
      watchers = source_class.watched_by
      if watchers.present?
        watchers.each do |watcher|
          @target       = @source
          @actions      = []
          watcher_class = watcher.to_s.camelize.constantize

          before_condition = begin
                               watcher_class.before_actions_for(source_key)[:conditions].inject(true) { |mem, condition| mem && (condition.is_a?(Hash) ? (condition.inject(true) { |hmem, hval| cnd = hval.last; hres = !!(cnd.is_a?(Proc) ? instance_exec(&cnd) : cnd ); hmem && (hval.first == :if ? hres : !(hres))}) : !!(condition.is_a?(Proc) ? instance_exec(&condition) : condition ))}
                             rescue
                               false
                             end

          if before_condition
            watcher_class.before_actions_for(source_key)[:actions].each do |action|
              instance_exec(&action)
            end
          end

          actions = watcher_class.matrix_for(source_key, meta[:action])

          if actions.present?
            actions.each do |action|
              @event_data = data[:data].attributes
              @event_data[:previous_changes] = @changes if @changes.present?


              conditions_result = begin
                                    action[:conditions].inject(true) { |mem, condition| mem && (condition.is_a?(Hash) ? (condition.inject(true) { |hmem, hval| cnd = hval.last; hres = !!(cnd.is_a?(Proc) ? instance_exec(&cnd) : cnd ); hmem && (hval.first == :if ? hres : !(hres))}) : !!(condition.is_a?(Proc) ? instance_exec(&condition) : condition ))}
                                  rescue
                                    false
                                  end

              if conditions_result
                instance_exec(&action[:yield])

                @actions << action[:name]
                @events << ::Event.new(action: action[:name], data: @event_data.to_json, author: data[:user],
                                       source_id: @source.id, source_type: @source.class.name,
                                       target_id: @target.id, target_type: @target.class.name,
                                       system_action: meta[:action])
              end

            end
          end
        end
      end

      @events
    end

    def find_parent_event(action, data)
      collector = EventHierarchyWorker.collector
      parent_event = collector.events.parent(action, data)

      if parent_event.present?
        action_meta = Gitlab::Event::Action.parse(parent_event[:name])
        event_info  = parent_event[:data]
        source      = event_info[:source]  if event_info[:source].present?
        user        = event_info[:user]    if event_info[:user].present?

        level = 0

        if source.present? && user.present? && source.respond_to?(:id)
          candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                   target_id: source.try(:id), target_type: source.class.name,
                                   author_id: user.id, system_action: action_meta[:action])

          if candidates.blank? && (source.is_a?(::Project) && action_meta[:action] == :updated)
            candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                     target_id: source.try(:id), target_type: source.class.name,
                                     author_id: user.id, action: :transfer)
          end

          level = 1

          if candidates.blank?
            candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                     author_id: user.id, system_action: action_meta[:action])
            level = 2
            if candidates.blank?
              # TODO
              # Make base_actions method to watchable classes
              base_actions = [:created, :updated, :deleted, :opened, :closed, :reopened, :merged, :blocked, :activate]

              candidates = Event.where(source_id: source.try(:id), source_type: source.class.name,
                                       target_id: source.try(:id), target_type: source.class.name,
                                       author_id: user.id).
                                       where("system_action not in (?)", base_actions)
              level = 3
            end
          end

          candidate = candidates.last

          if candidate
            return nil if candidate.notifications.where(notification_state: [:delivered, :new]).any?
            return candidate.parent_event if candidate.parent_event.present? && level > 1
            return candidate
          end
        end
      end
      nil
    end

  end
end
