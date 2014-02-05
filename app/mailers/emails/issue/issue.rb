class Emails::Issue::Issue < Emails::Base
  def created_email(notification)
    case notification.subscription
    when NilClass
        Emails::Project::Issue.opened_email(notification).deliver!
    else
      case notification.subscription.target
      when Project
        Emails::Project::Issue.opened_email(notification).deliver!
      when Issue
        # Send notification
      end
    end
  end

  def closed_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::Issue.closed_email(notification).deliver!
    when Issue
      # Send notification
    end
  end

  def updated_email(notification)

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
