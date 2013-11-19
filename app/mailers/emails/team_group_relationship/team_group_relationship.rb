class Emails::TeamGroupRelationship::TeamGroupRelationship < Emails::Base
  def created_email(notification)
    case notification.subscription.target
    when Team
      Emails::Team::TeamGroupRelationship.assigned_email(notification).deliver!
    when Group
      Emails::Group::TeamGroupRelationship.assigned_email(notification).deliver!
    when User
      Emails::User::TeamGroupRelationship.joined_email(notification).deliver!
    end
  end

  def deleted_email(notification)
    subscription = notification.subscription
    if subscription
      case subscription.target_type
      when "Team"
        Emails::Team::TeamGroupRelationship.resigned_email(notification).deliver!
      when "Group"
        Emails::Group::TeamGroupRelationship.resigned_email(notification).deliver!
      when "User"
        Emails::User::TeamGroupRelationship.left_email(notification).deliver!
      end
    end
  end
end
