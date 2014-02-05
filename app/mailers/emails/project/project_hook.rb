class Emails::Project::ProjectHook < Emails::Project::Base
  def added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project_hook = @event.source
    @project      = @project_hook.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'project_hook',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-project_hook-#{@project_hook.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hooks")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project_hook = @event.source
    @project      = @project_hook.project
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project_hook',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-project_hook-#{@project_hook.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hooks")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @project      = @event.target
    @project_hook = data

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'project_hook',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-project_hook-#{@project_hook["id"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hooks")
  end
end
