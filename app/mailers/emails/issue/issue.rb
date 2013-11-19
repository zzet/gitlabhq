class Emails::Issue::Issue < Emails::Base
  def created_email(notification)

  end

  def closed_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::Issue.closed_email(notification).deliver!
    when Issue
      # Send notification
    end
  end

  def reopened_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::Issue.reopened_email(notification).deliver!
    when Issue
      # Send notification
    end
  end
end
