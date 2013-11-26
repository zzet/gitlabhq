class Emails::MergeRequest::Note < Emails::Base
  def commented_email(notification)
    Emails::Project::Note.commented_merge_request_email(notification).deliver!
  end
end
