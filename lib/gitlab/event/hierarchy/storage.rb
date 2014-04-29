class Gitlab::Event::Hierarchy::Storage
  def initialize
    RequestStore.store[:events_hierarchy_store] ||= []
  end

  def events
    RequestStore.store[:events_hierarchy_store] ||= []
  end

  def clear
    events.clear
  end

  def find(action)
    find_recursive(events.last, action)
  end

  # Put current event in events tree
  def put args
    if events.blank?
      events << {name: args[:name], data: args[:data], childrens: []}
    else
      find_place_and_put(events, args)
    end
  end

  # Find level and parent to put event
  #
  #        1| A |
  #           |
  #         _ _ _
  #        |     |
  #      2|B|  5|B|
  #        |     |
  #      _ _ _ _ _ _
  #      |   | |   |
  #     3c  4c 6c  7c
  #
  def find_place_and_put(event_list, arg)
    if lvl_to_put?(event_list, arg)
      event_list << {name: arg[:name], data: arg[:data], childrens: []}
    else
      if event_list.last[:childrens].any?
        find_place_and_put(event_list.last[:childrens], arg)
      else
        event_list.last[:childrens] << {name: arg[:name], data: arg[:data], childrens: []}
      end
    end
  end

  def lvl_to_put?(lvl, arg)
    if lvl.any?
      lvl_meta = Gitlab::Event::Action.parse(lvl.first[:name])
      arg_meta = Gitlab::Event::Action.parse(arg[:name])
      return lvl_meta == arg_meta ? true : ((lvl_meta[:details] == arg_meta[:details]) && (!lvl_meta[:details].blank?))
    end
  end

  def parent(action, data)
    return nil if events.blank?

    if events.first[:name] == events.last[:name]
      if events.last[:name].include?(action) && events.last[:childrens].blank?
        events.last
      else
        find_parent_event(events.last, action)
      end
    else
      events.first[:name].include?(action) ? events.first : find_parent_event(events.last, action)
    end
  end

  def find_parent_event(event, action)
    parent_event = nil

    if event[:childrens].any?
      parent_event = if event[:childrens].last[:name].include?(action)
                       event[:name].include?(action) ? event[:childrens].last : event
                     else
                       find_parent_event(event[:childrens].last, action)
                     end
    end

    parent_event
  end

  private

  def find_recursive(event, action)
    return event if event[:name] == action

    if event[:childrens].any?
      find_recursive(event[:childrens].last, action)
    else
      nil
    end
  end
end
