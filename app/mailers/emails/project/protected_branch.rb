class Emails::Project::ProtectedBranch < Emails::Project::Base
  def protected_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @branch       = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'protected_branch',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-branch-#{@branch.name}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] [#{@branch.name}] Branch status")
  end

  def unprotected_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @project      = @event.target
    @branch       = data

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'removed',
            'X-Gitlab-Source' => 'protected_branch',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-branch-#{@branch["name"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] [#{@branch["name"]}] Branch status")
  end
end
