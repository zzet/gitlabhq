module Projects::NotesActions
  private

  def create_note_action
    note = project.notes.new(params[:note])
    note.author = current_user
    note.save

    receive_delayed_notifications

    note
  end

  def load_notes_action(target_type, target_id)
    @notes = case target_type
             when "commit"
               project.notes.for_commit_id(target_id).not_inline.fresh
             when "issue"
               project.issues.find(target_id).notes.inc_author.fresh
             when "merge_request"
               project.merge_requests.find(target_id).mr_and_commit_notes.inc_author.fresh
             when "snippet"
               project.snippets.find(target_id).notes.fresh
             end
  end
end
