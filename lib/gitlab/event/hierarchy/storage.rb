class Gitlab::Event::Hierarchy::Storage
  def initialize
    RequestStore.store[:events_hierarchy_store] ||= []
  end

  def events
    RequestStore.store[:events_hierarchy_store] ||= []
  end

  def clear
    RequestStore.store[:events_hierarchy_store].clear
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
      lvl_meta = Gitlab::Event::Action.parse(lvl.first[:name])
      arg_meta = Gitlab::Event::Action.parse(arg[:name])
      return lvl_meta == arg_meta ? true : lvl_meta[:details] == arg_meta[:details]
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
