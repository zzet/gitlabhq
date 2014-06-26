class Emails::Project::MergeRequest < Emails::Project::Base
  def opened_email(notification)
    @notification  = notification
    @event         = @notification.event
    @user          = @event.author
    @merge_request = @event.source
    @project       = @merge_request.target_project

    set_x_gitlab_headers(:project, :merge_request, :opened, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def updated_email(notification)

  end

  def closed_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project

    set_x_gitlab_headers(:project, :merge_request, :closed, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def merged_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project

    set_x_gitlab_headers(:project, :merge_request, :merged, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def assigned_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project
    @assigned_user  = @merge_request.assignee

    set_x_gitlab_headers(:project, :merge_request, :assigned, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def reassigned_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project
    @assigned_user  = @event.target

    set_x_gitlab_headers(:project, :merge_request, :reassigned, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def reopened_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project

    set_x_gitlab_headers(:project, :merge_request, :reopened, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end
end
