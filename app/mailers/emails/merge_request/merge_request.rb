class Emails::MergeRequest::MergeRequest < Emails::Base
  def created_email(notification)
    case notification.subscription
    when NilClass
      Emails::Project::MergeRequest.opened_email(notification).deliver!
    else
      case notification.subscription.target
      when Project
        Emails::Project::MergeRequest.opened_email(notification).deliver!
      when MergeRequest
        # Send notification
      end
    end
  end

  def updated_email(notification)

  end

  def assigned_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::MergeRequest.assigned_email(notification).deliver!
    when MergeRequest
      # Send notification
    end
  end

  def reassigned_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::MergeRequest.reassigned_email(notification).deliver!
    when MergeRequest
      # Send notification
    end
  end

  def reopened_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::MergeRequest.reopened_email(notification).deliver!
    when MergeRequest
      # Send notification
    end
  end

  def closed_email(notification)
    case notification.subscription
    when NilClass
      Emails::Project::MergeRequest.closed_email(notification).deliver!
    else
      case notification.subscription.target
      when Project
        Emails::Project::MergeRequest.closed_email(notification).deliver!
      when MergeRequest
        # Send notification
      end
    end
  end
end
