class MergeRequestObserver < ActiveRecord::Observer
  cattr_accessor :current_user

  def after_close(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end

  def after_reopen(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end
end
