class Gitlab::Event::Builder
  class << self
    def build(event_action, data)
      meta = Gitlab::Event::Action.parse(event_action)

      @source  = data[:source]
      @actions = []
      @changes = (meta[:action] == :update ? @source.changes : nil)

      source_class = @source.class
      source_key = meta[:source]

      @events = []
      watchers = source_class.watched_by
      if watchers.present?
        watchers.each do |watcher|
          @target       = @source
          watcher_class = watcher.to_s.camelize.constantize

          before_condition = begin
                               watcher_class.before_actions_for(source_key)[:conditions].inject(true) do |mem, condition|
                                 if mem && condition.is_a?(Hash)
                                   condition.inject(true) do |hmem, hval|
                                     cnd = hval.last
                                     hres = !!(cnd.is_a?(Proc) ? instance_exec(&cnd) : cnd)
                                     hmem && (hval.first == :if ? hres : !(hres))
                                   end
                                 else
                                   !!(condition.is_a?(Proc) ? instance_exec(&condition) : condition )
                                 end
                               end
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
                                    action[:conditions].inject(true) do |mem, condition|
                                      if mem && condition.is_a?(Hash)
                                        condition.inject(true) do |hmem, hval|
                                          cnd = hval.last
                                          hres = !!(cnd.is_a?(Proc) ? instance_exec(&cnd) : cnd )
                                          hmem && (hval.first == :if ? hres : !(hres))
                                        end
                                      else
                                        !!(condition.is_a?(Proc) ? instance_exec(&condition) : condition )
                                      end
                                    end
                                  rescue
                                    false
                                  end

              if conditions_result
                instance_exec(&action[:yield])
                @actions << action[:name]

                hierarchy_event = EventHierarchyWorker.collector.events.find(event_action)

                @events << ::Event.new(
                  action: action[:name],
                  data: @event_data,
                  author: data[:user],
                  source_id: @source.id,
                  source_type: @source.class.name,
                  target_id: @target.id,
                  target_type: @target.class.name,
                  system_action: meta[:action],
                  uniq_hash: hierarchy_event[:data][:uniq_hash]
                )

                @events
              end

            end
          end
        end
      end

      @events.flatten
    end

    def find_parent_event(action, data, step = 0)
      collector = EventHierarchyWorker.collector
      parent_event = collector.events.parent(action, data)

      event = Event.find_by(uniq_hash: parent_event[:data][:uniq_hash])

      if event.nil? &&
                      (collector.events.parent(parent_event[:name],
                                               parent_event[:data]).present? &&
                      parent_event[:name] != action &&
                      step < 3)

        step += 1
        event = find_parent_event(parent_event[:name], parent_event[:data], step)
      end

      event
    end

    def find_persisted_event(action)
      collector = EventHierarchyWorker.collector
      parent_event = collector.events.find(action)

      Event.find_by(uniq_hash: parent_event[:data][:uniq_hash])
    end

  end
end
