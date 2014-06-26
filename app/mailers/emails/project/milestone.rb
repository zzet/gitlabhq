class Emails::Project::Milestone < Emails::Project::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @milestone    = @event.source
    @project      = @milestone.project

    set_x_gitlab_headers(:project, :milestone, :opened, "project-#{@project.path_with_namespace}-milestone-#{@milestone.id}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Milestone '#{@milestone.title}'")
  end

  def closed_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @milestone    = @event.source
    @project      = @milestone.project

    set_x_gitlab_headers(:project, :milestone, :closed, "project-#{@project.path_with_namespace}-milestone-#{@milestone.id}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Milestone '#{@milestone.title}'")
  end
end
