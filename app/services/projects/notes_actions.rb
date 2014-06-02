module Projects::NotesActions
  private

  FETCH_OVERLAP = 5.seconds

  def create_note_action
    note = project.notes.new(params[:note])
    note.author = current_user
    note.save

    receive_delayed_notifications

    note
  end

  def load_notes_action(target_type, target_id)
    # Default to 0 to remain compatible with old clients
    last_fetched_at = Time.at(params.fetch(:last_fetched_at, 0).to_i)

    @notes = case target_type
             when "commit"
               project.notes.for_commit_id(target_id).not_inline.fresh
             when "issue"
               project.issues.find(target_id).notes.inc_author.fresh
             when "merge_request"
               project.merge_requests.find(target_id).mr_and_commit_notes.inc_author.fresh
             when "snippet"
               project.snippets.find(target_id).notes.fresh
             else
               raise 'invalid target_type'
             end
    # Use overlapping intervals to avoid worrying about race conditions
    @notes = @notes.where('updated_at > ?', last_fetched_at - FETCH_OVERLAP)
  end
end
