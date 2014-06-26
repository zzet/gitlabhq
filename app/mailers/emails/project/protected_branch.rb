class Emails::Project::ProtectedBranch < Emails::Project::Base
  def protected_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @branch       = @event.source
    @project      = @event.target

    set_x_gitlab_headers(:project, :protected_branch, :created, "project-#{@project.path_with_namespace}-protected_branch-#{@branch.name}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] [#{@branch.name}] Branch status")
  end

  def unprotected_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @project      = @event.target
    @branch       = data

    set_x_gitlab_headers(:project, :protected_branch, :deleted, "project-#{@project.path_with_namespace}-protected_branch-#{@branch['name']}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] [#{@branch["name"]}] Branch status")
  end
end
