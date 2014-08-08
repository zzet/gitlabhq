class Emails::Note::Note < Emails::Base
  def created_email(notification)
    case notification.subscription
    when NilClass
      case notification.event.source.noteable
      when MergeRequest
        Emails::Project::Note.commented_merge_request_email(notification).deliver!
      when Commit
        Emails::Project::Note.commented_commit_email(notification).deliver!
      when Issue
        Emails::Project::Note.commented_issue_email(notification).deliver!
      else
        raise "wow"
      end
    else
      case notification.event.source.noteable_type
      when "MergeRequest"
        Emails::Project::Note.commented_merge_request_email(notification).deliver!
      when "Commit"
        Emails::Project::Note.commented_commit_email(notification).deliver!
      when "Issue"
        Emails::Project::Note.commented_issue_email(notification).deliver!
      else
        raise "wow"
      end
    end
  end
end
