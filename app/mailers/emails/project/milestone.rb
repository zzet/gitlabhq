class Emails::Project::Milestone < Emails::Project::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @milestone    = @event.source
    @project      = @milestone.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'opened',
            'X-Gitlab-Source' => 'milestone',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-milestone-#{@milestone.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Milestone '#{@milestone.title}'")
  end

  def closed_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @milestone    = @event.source
    @project      = @milestone.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'closed',
            'X-Gitlab-Source' => 'milestone',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-milestone-#{@milestone.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Milestone '#{@milestone.title}'")
  end
end
