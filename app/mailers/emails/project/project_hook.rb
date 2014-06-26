class Emails::Project::ProjectHook < Emails::Project::Base
  def added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project_hook = @event.source
    @project      = @project_hook.project

    set_x_gitlab_headers(:project, :project_hook, :created, "project-#{@project.path_with_namespace}-project_hook-#{@project_hook.id}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hooks")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project_hook = @event.source
    @project      = @project_hook.project
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:project, :project_hook, :updated, "project-#{@project.path_with_namespace}-project_hook-#{@project_hook.id}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hooks")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @project      = @event.target
    @project_hook = data

    set_x_gitlab_headers(:project, :project_hook, :deleted, "project-#{@project.path_with_namespace}-project_hook-#{@project_hook['id']}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hooks")
  end
end
