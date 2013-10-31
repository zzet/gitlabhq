class IssueObserver < BaseObserver
  def after_create(issue)
    issue.create_cross_references!(issue.project, current_user)
  end

  def after_close(issue, transition)
    create_note(issue)
  end

  def after_reopen(issue, transition)
    create_note(issue)
  end

  def after_update(issue)
    issue.notice_added_references(issue.project, current_user)
  end

  protected

  # Create issue note with service comment like 'Status changed to closed'
  def create_note(issue)
    Note.create_status_change_note(issue, issue.project, current_user, issue.state, current_commit)
  end
end
