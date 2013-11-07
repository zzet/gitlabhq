class Emails::Project::MergeRequest < Emails::Project::Base
  def opened_email(notification)
    @notification  = notification
    @event         = @notification.event
    @user          = @event.author
    @merge_request = @event.source
    @project       = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.id})")
  end

  def merged_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @merge_request  = @event.source
    @project        = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'merged',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.id})")
  end
end
