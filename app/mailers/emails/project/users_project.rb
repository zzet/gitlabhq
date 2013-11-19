class Emails::Project::UsersProject < Emails::Project::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = @event.source
    @project      = @event.target
    @member       = @up.user
    @project      = @up.project if @project.is_a?(UsersProject)

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'joined',
            'X-Gitlab-Source' => 'project-user-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] User '#{@member.name}' was added")
  end

  def updated_email(notification)
    @notification         = notification
    @event                = @notification.event
    @user                 = @event.author
    @upr                  = @event.source
    data                  = JSON.load(@event.data)
    @project              = Project.find(data["project_id"])
    @member               = User.find(data["user_id"])
    @changes              = data["previous_changes"]
    unless @changes.blank?
      @previous_permission  = UsersProject.access_roles.key(@changes["project_access"].first)
      @current_permission   = UsersProject.access_roles.key(@changes["project_access"].last)

      headers 'X-Gitlab-Entity' => 'project',
              'X-Gitlab-Action' => 'updated',
              'X-Gitlab-Source' => 'project-user-relationship',
              'In-Reply-To'     => "project-#{@project.path_with_namespace}-user-#{@member.username}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Permissions for user '#{ @member.name }' was updated")
    end
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = JSON.load(@event.data)
    @project      = @event.target
    @member       = User.find(@up["user_id"])
    @project      = Project.find(@up["project_id"]) if @project.nil? || @project.is_a?(UsersProject)

    if @member && @project
    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'left',
            'X-Gitlab-Source' => 'project-user-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-user-#{@member.username}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] User '#{@member.name}' was removed from project team")
    end
  end
end
