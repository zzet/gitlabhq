class NotesService < BaseService
  attr_accessor :current_user, :project, :params

  def initialize(user, project, params = {})
    @current_user, @project, @params = user, project, params.dup
  end

  def create
    note = project.notes.new(params[:note])
    note.author = current_user
    note.system = false
    note.save

    receive_delayed_notifications

    note
  end

  def load
    target_type = params[:target_type]
    target_id   = params[:target_id]

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
