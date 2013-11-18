class Emails::UsersProject::UsersProject < Emails::Base
  def created_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::UsersProject.joined_email(notification).deliver!
    when User
      Emails::User::UsersProject.joined_email(notification).deliver!
    end
  end

  def updated_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::UsersProject.updated_email(notification).deliver!
    when User
      Emails::User::UsersProject.updated_email(notification).deliver!
    end
  end

  def deleted_email(notification)
    case notification.subscription.target
    when Project
      Emails::Project::UsersProject.left_email(notification).deliver!
    when User
      Emails::User::UsersProject.left_email(notification).deliver!
    end
  end
end
