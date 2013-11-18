class Emails::UsersGroup::UsersGroup < Emails::Base
  def created_email(notification)
    case notification.subscription.target
    when Group
      Emails::Group::UsersGroup.joined_email(notification).deliver!
    when User
      Emails::User::UsersGroup.joined_email(notification).deliver!
    end
  end

  def updated_email(notification)
    case notification.subscription.target
    when Group
      Emails::Group::UsersGroup.updated_email(notification).deliver!
    when User
      Emails::User::UsersGroup.updated_email(notification).deliver!
    end
  end

  def deleted_email(notification)
    subscription = notification.subscription
    if subscription
      case subscription.target_type
      when "Group"
        Emails::Group::UsersGroup.left_email(notification).deliver!
      when "User"
        Emails::User::UsersGroup.left_email(notification).deliver!
      end
    end
  end
end
