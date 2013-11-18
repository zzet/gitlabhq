class Emails::Project::ProtectedBranch < Emails::Project::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @branch       = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'protected_branch',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-branch-#{@branch.name}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] [#{@branch.name}] Branch status was changed to protected mode")
  end

  def deleted_email(notification)

  end
end
