class Emails::Project::Issue < Emails::Project::Base
  def opened_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project

    if @user && @project && @issue
      headers 'X-Gitlab-Entity' => 'project',
        'X-Gitlab-Action' => 'opened',
        'X-Gitlab-Source' => 'issue',
        'In-Reply-To'     => "project-#{@project.path_with_namespace}-issue-#{@issue.iid}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
    end
  end

  def closed_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'closed',
            'X-Gitlab-Source' => 'issue',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-issue-#{@issue.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
  end

  def reopened_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'reopened',
            'X-Gitlab-Source' => 'issue',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-issue-#{@issue.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
  end

  def deleted_email(notification)

  end

  def updated_email(notification)

  end
end
