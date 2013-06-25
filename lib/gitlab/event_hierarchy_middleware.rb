class Gitlab::EventHierarchyMiddleware

  def initialize(appl)
    @appl = appl
  end

  def call(env)

    env["event_action_collector"] = ::EventHierarchyWorker

    def env.event_action_collector
      self["event_action_collector"]
    end

    env["event_action_collector"].reset

    status, headers, body = @appl.call(env)

    env["event_action_collector"].reset

    [status, headers, body]
  end
end

class EventHierarchyCollector
  def initialize
    @events = EventHierarchyStorage.new
  end

  def << args
    if args.is_a? Array
      args.each { |arg| events.put arg }
    else
      events.put args
    end
  end

  def events
    @events
  end

  def reset
    @events.clear
  end
end

class EventHierarchyStorage
  def initialize
    @events = []
  end

  def events
    @events ||= []
  end

  def clear
    @events.clear
  end

  def put args
    if events.blank?
      events << { name: args[:name], data: args[:data], childrens: [] }
    else
      find_place_and_put(events, args)
    end
  end

  def find_place_and_put(event_list, arg)
    if lvl_to_put?(event_list, arg)
      event_list << { name: arg[:name], data: arg[:data], childrens: [] }
    else
      if event_list.last[:childrens].any?
        find_place_and_put(event_list.last[:childrens], arg)
      else
        event_list.last[:childrens] << { name: arg[:name], data: arg[:data], childrens: [] }
      end
    end
  end

  def lvl_to_put?(lvl, arg)
    if lvl.any?
      return lvl.first[:name] == arg[:name]
    end
  end

  def parent(action, data)
    return nil if events.blank?

    parent_event = events.first[:name] == action ? events.first : find_event(events.last, action, data)
    parent_event
  end

  def find_event(event, action, data)
    parent_event = nil

    if event[:childrens].any?
      parent_event = event[:childrens].last[:name] == action ? event : find_event(event[:childrens].last, action, data)
    end

    parent_event
  end
end
