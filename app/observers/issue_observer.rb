class IssueObserver < ActiveRecord::Observer
  cattr_accessor :current_user

  def after_close(issue, transition)
    create_note(issue)
  end

  def after_reopen(issue, transition)
    create_note(issue)
  end

  protected

  def create_note(issue)
    Note.create_status_change_note(issue, current_user, issue.state)
  end
end
