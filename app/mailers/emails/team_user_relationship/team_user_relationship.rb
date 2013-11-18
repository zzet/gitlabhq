class Emails::TeamUserRelationship::TeamUserRelationship < Emails::Base
  def created_email(notification)
    case notification.subscription.target
    when Team
      Emails::Team::TeamUserRelationship.joined_email(notification).deliver!
    when User
      Emails::User::TeamUserRelationship.joined_email(notification).deliver!
    end
  end

  def updated_email(notification)
    case notification.subscription.target
    when Team
      Emails::Team::TeamUserRelationship.updated_email(notification).deliver!
    when User
      Emails::User::TeamUserRelationship.updated_email(notification).deliver!
    end
  end

  def deleted_email(notification)
    subscription = notification.subscription
    if subscription
      case subscription.target_type
      when "Team"
        Emails::Team::TeamUserRelationship.left_email(notification).deliver!
      when "User"
        Emails::User::TeamUserRelationship.left_email(notification).deliver!
      end
    end
  end
end
