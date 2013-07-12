class OldEventToNewEventMigrator
  def initialize

  end

  def migrate!
    OldEvent.find_each do |oe|
      case oe.target_type
      when "MergeRequest"
        migrate_merge_request_event(oe)
      when "Issue"
      when "Note"
      else
      end
      #when 1
      # CREATED
      #when 2
      # UPDATED
      #when 3
      # CLOSED
      #when 4
      # REOPENED
      #when 5
      # PUSHED
      #when 6
      # COMMENTED
      #when 7
      # MERGED
      #when 8
      # JOINED
      #when 9
      # LEFT
    end
  end

  def remove_uanactual_events
    Event.where(action: :updated, source_type: "User").destroy_all
  end

  def convert_our_events
    Event.find_each do |event|
      if event.data.is_a? String
        data = JSON.load(event.data).to_hash
        data.symbolize_keys!
        event.data = data
      end

      event.save
    end
  end

  def symbolize_data(data)
    data.each do |k, v|
      data[k] = case v
                when Hash
                  v.symbolize_keys!
                when Array
                  v.each {|a| a.symbolize_keys!; symbolize_data(a)}
                else
                  v
                end
    end
    data
  end

  def migrate_merge_request_event(merge_request_event)
    # Related to project event
    if [1, 2, 3, 7].include?(merge_request_event.action)

      action = nil

      case merge_request_event.action
      when 1
        action = :opened
      when 3
        action = :closed
      when 4
        action = :reopened
      end

      Gitlab::Event.create_events(name, data)
      create_event(merge_request_event, action)
    end
  end

  def migrate_issue_event(issue_event)
    # Related to project event
    if [1, 3, 4].include?(action)

      action = nil

      case issue_event.action
      when 1
        action = :opened
      when 3
        action = :closed
      when 4
        action = :reopened
      end

      Event.create(
        author_id: issue_event.author_id,
        action: action,
        source_id: issue_event.target_id,
        source_type: issue_event.target_type,
        target_id: issue_event.target_id,
        target_type: issue_event.target_type,
        data: "", # :(
        created_at: issue_event.created_at,
        updated_at: issue_event.updated_at
      )
    end

    # Related to issue event
    if [3, 4].include?(issue_event.action)

      action = nil

      case issue_event.action
      when 3
        action = :closed
      when 4
        action = :reopened
      end

      Event.create(
        author_id: issue_event.author_id,
        action: action,
        source_id: issue_event.target_id,
        source_type: issue_event.target_type,
        target_id: issue_event.project_id,
        target_type: "Project",
        data: "", # :(
        created_at: issue_event.created_at,
        updated_at: issue_event.updated_at
      )
    end
  end

  def migrate_merge_request_event(merge_request_event)
    # Related to project event
    if [1, 3, 4].include?(action)

      action = nil

      case issue_event.action
      when 1
        action = :opened
      when 3
        action = :closed
      when 4
        action = :reopened
      end

      create_event(merge_request_event, action)
    end

    # Related to issue event
    if [3, 4, 7].include?(issue_event.action)

      action = nil

      case issue_event.action
      when 3
        action = :closed
      when 4
        action = :reopened
      when 7
        action = :merged
      end

      create_event(issue_event, action)
    end
  end

  def create_event(event, action, data)
    events = Gitlab::Event::Factory.build(action, data)

    if events.any?
      parent_event = Gitlab::Event::Builder::Base.find_parent_event(action, data)

      if parent_event.blank?
        events.each_with_index do |e, i|
          if e.source == e.target
            e.save
            events.delete_at(i)
          end
        end
        parent_event = Gitlab::Event::Builder::Base.find_parent_event(action, data)
      end

      events.each do |event|
        event.parent_event = parent_event if parent_event.present?
        event.save
      end
    end
  end
end
