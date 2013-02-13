class OldActivityObserver < ActiveRecord::Observer
  observe :issue, :merge_request, :note, :milestone

  def after_create(record)
    event_author_id = record.author_id

    # Skip status notes
    if record.kind_of?(Note) && record.note.include?("_Status changed to ")
      return true
    end

    if event_author_id
      OldEvent.create(
        project: record.project,
        target_id: record.id,
        target_type: record.class.name,
        action: OldEvent.determine_action(record),
        author_id: event_author_id
      )
    end
  end

  def after_close(record, transition)
    OldEvent.create(
      project: record.project,
      target_id: record.id,
      target_type: record.class.name,
      action: OldEvent::CLOSED,
      author_id: record.author_id_of_changes
    )
  end

  def after_reopen(record, transition)
    OldEvent.create(
      project: record.project,
      target_id: record.id,
      target_type: record.class.name,
      action: OldEvent::REOPENED,
      author_id: record.author_id_of_changes
    )
  end

  def after_merge(record, transition)
    # Since MR can be merged via sidekiq
    # to prevent event duplication do this check
    return true if record.merge_event

    Event.create(
      project: record.project,
      target_id: record.id,
      target_type: record.class.name,
      action: Event::MERGED,
      author_id: record.author_id_of_changes
    )
  end
end
