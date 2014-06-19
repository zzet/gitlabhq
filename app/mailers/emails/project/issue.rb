class Emails::Project::Issue < Emails::Project::Base
  def opened_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project

    if @user && @project && @issue
      set_x_gitlab_headers(:project, :issue, :opened, "project-#{@project.path_with_namespace}-issue-#{@issue.iid}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
    end
  end

  def closed_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project

    set_x_gitlab_headers(:project, :issue, :closed, "project-#{@project.path_with_namespace}-issue-#{@issue.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
  end

  def reopened_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project

    set_x_gitlab_headers(:project, :issue, :reopened, "project-#{@project.path_with_namespace}-issue-#{@issue.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
  end

  def deleted_email(notification)

  end

  def updated_email(notification)

  end
end
