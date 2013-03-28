class OldEventToNewEventMigrator
  def initialize

  end

  def migrate!
    OldEvent.find_each do |oe|
      case oe.target_type
      when 1
        # CREATED
        case oe.target_type
        when "Issue"
        when "MergeRequest"
        else
        end
      when 2
        # UPDATED
      when 3
        # CLOSED
      when 4
        # REOPENED
      when 5
        # PUSHED
      when 6
        # COMMENTED
      when 7
        # MERGED
      when 8
        # JOINED
      when 9
        # LEFT
      end
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

end
