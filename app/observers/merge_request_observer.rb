class MergeRequestObserver < BaseObserver
  cattr_accessor :current_user

  def after_close(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)

    notification.close_mr(merge_request, current_user)
  end

  def after_merge(merge_request, transition)
    notification.merge_mr(merge_request)
  end

  def after_reopen(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end
end
