class Emails::Project::MergeRequest < Emails::Project::Base
  def opened_email(notification)
    @notification  = notification
    @event         = @notification.event
    @user          = @event.author
    @merge_request = @event.source
    @project       = @merge_request.target_project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def closed_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'closed',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def merged_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'merged',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def assigned_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project
    @assigned_user  = @merge_request.assignee

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'assigned',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def reassigned_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project
    @assigned_user  = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'reassigned',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end

  def reopened_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @merge_request.target_project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'reopened',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
  end
end
