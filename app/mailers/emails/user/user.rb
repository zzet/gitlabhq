class Emails::User::User < Emails::User::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @new_user     = @event.source

    set_x_gitlab_headers(:user, :user, :created, "user-#{@new_user.username}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New user '#{@new_user.name}' was created")
  end

  def blocked_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @banned_user  = @event.source
    data          = @event.data
    @teams        = data["teams"].map { |t| Team.find_by_id(t["id"]) }.reject { |t| t.nil? }
    @projects     = data["projects"].map { |pr| Project.find_by_id(pr["id"]) }.reject { |pr| pr.nil? }

    set_x_gitlab_headers(:user, :user, :banned, "user-#{@banned_user.username}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@banned_user.name}' was banned")
  end

  def activate_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @activated_user = @event.source

    set_x_gitlab_headers(:user, :user, :activated, "user-#{@activated_user.username}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@activated_user.name}' was activated")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @updated_user = @event.source
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:user, :user, :updated, "user-#{@updated_user.username}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@updated_user.name}' was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @deleted_user = data

    set_x_gitlab_headers(:user, :user, :deleted, "user-#{@deleted_user['username']}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@deleted_user['name']}' was removed")
  end
end
