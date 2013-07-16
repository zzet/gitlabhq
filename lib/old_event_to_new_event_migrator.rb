class OldEventToNewEventMigrator
  def initialize

  end

  def migrate!
    OldEvent.find_each do |oe|
      if no_new_event(oe)
        case oe.target_type
        when "MergeRequest"
          migrate_merge_request_event(oe)
        when "Issue"
          migrate_issue_event(oe)
        when "Note"
        else
        end
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
        event.data = symbolize_data(data)
        event.save
      end
    end
  end

  def move_push_event_data_to_push_model
    Event.where(source_type: "Push_summary").find_each do |event|
      data = JSON.load(event.data).to_hash

      data.symbolize_keys!
      data = symbolize_data(data)

      push = Push.new(
        before: data[:before],
        after: data[:after],
        ref: data[:ref],
        data: data,
        project_id: event.target_id,
        user_id: data[:user_id])

        push.save
        event.source = push
        event.data = push.attributes
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
        action = :created
      when 3
        action = :closed
      when 4
        action = :reopened
      end

      create_event(merge_request_event, action, merge_request_event.target)
    end
  end

  def migrate_issue_event(issue_event)
    # Related to project event
    if [1, 3, 4].include?(issue_event.action)

      action = nil

      case issue_event.action
      when 1
        action = :created
      when 3
        action = :closed
      when 4
        action = :reopened
      end

      create_event(issue_event, action, issue_event.target)
    end
  end

  def create_event(or_event, action, source)
    begin
      user = User.find(or_event.author_id)
      data = {source: source, user: user, data: source}
      action = "gitlab.#{action}.#{source.class.name}".underscore.downcase

      events = Gitlab::Event::Factory.build(action, data)

      if events.any?
        parent_event = Gitlab::Event::EventBuilder::Base.find_parent_event(action, data)

        if parent_event.blank?
          events.each_with_index do |e, i|
            if e.source == e.target
              e.created_at = or_event.created_at
              e.save
              events.delete_at(i)
            end
          end
          parent_event = Gitlab::Event::EventBuilder::Base.find_parent_event(action, data)
        end

        events.each do |event|
          event.parent_event = parent_event if parent_event.present?
          event.created_at = or_event.created_at
          event.save
        end
      end
    end
  end

  def no_new_event(old_event)
    return false if old_event.target.nil?
    Event.where(source_type: old_event.target_type, source_id: old_event.target_id, created_at: old_event.created_at).blank?
  end
end
