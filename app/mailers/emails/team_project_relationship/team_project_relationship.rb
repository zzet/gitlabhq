class Emails::TeamProjectRelationship::TeamProjectRelationship < Emails::Base
  def created_email(notification)
    subscription_target = notification.subscription.target
    case subscription_target
    when Team
      Emails::Team::TeamProjectRelationship.assigned_email(notification).deliver!
    when Project
      Emails::Project::TeamProjectRelationship.assigned_email(notification).deliver!
    when Group
      Emails::Group::TeamProjectRelationship.assigned_email(notification).deliver!
    else

    end
  end

  def deleted_email(notification)
    subscription_target = notification.subscription.target
    case subscription_target
    when Team
      Emails::Team::TeamProjectRelationship.resigned_email(notification).deliver!
    when Project
      Emails::Project::TeamProjectRelationship.resigned_email(notification).deliver!
    when Group
      Emails::Group::TeamProjectRelationship.resigned_email(notification).deliver!
    else

    end
  end
end
