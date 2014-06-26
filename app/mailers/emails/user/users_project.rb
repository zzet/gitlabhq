class Emails::User::UsersProject < Emails::User::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = @event.source
    @project      = @up.project
    @member       = @up.user
    @member       = @up.user if @member.is_a?(UsersProject)

    set_x_gitlab_headers(:user, 'user-project-relationship', :joined, "user-#{@member.username}-project-#{@project.path_with_namespace}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@member.name}' was added to '#{@project.path_with_namespace}' project")
  end

  def updated_email(notification)
    @notification        = notification
    @event               = @notification.event
    @user                = @event.author
    @upr                 = @event.source
    @member              = @upr.user
    @project             = @upr.project
    data                 = @event.data
    @changes             = data["previous_changes"]
    unless @changes.blank?
      @previous_permission = UsersProject.access_roles.key(@changes["project_access"].first)
      @current_permission  = UsersProject.access_roles.key(@changes["project_access"].last)

      set_x_gitlab_headers(:user, 'user-project-relationship', :updated, "user-#{@member.username}-project-#{@project.path_with_namespace}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Permissions for user '#{ @member.name }' in project '#{@project.path_with_namespace}' was updated")
    end
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = @event.data
    @member       = @event.target
    @project      = Project.find_by_id(@up["project_id"])
    @member       = User.find_by_id(@up["user_id"]) if @member.nil? || @member.is_a?(UsersProject)

    if @project && @member
      set_x_gitlab_headers(:user, 'user-project-relationship', :left, "user-#{@member.username}-project-#{@project.path_with_namespace}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@member.name}' was removed from '#{@project.path_with_namespace}' project team")
    end
  end
end
