class Emails::Group::Project < Emails::Group::Base
  def added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @group        = @event.target

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "group-#{@group.path}-project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project '#{@project.path}' was added to '#{@group.name}' group")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @group        = @event.target
    @changes      = @event.data["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "group-#{@group.path}-project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was updated")
  end

  def removed_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @project        = @event.source
    @group          = @event.target
    @owner_changes  = @event.data["owner_changes"]["namespace_id"]
    @old_owner      = Namespace.find(@owner_changes.first)
    @new_owner      = Namespace.find(@owner_changes.last)

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'transfer',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "group-#{@group.path}-project-#{@old_owner.path}/#{@project.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@old_owner.path}/#{@project.path}] Owner of project was changed")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @project      = data
    @group        = @event.target

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "group-#{@group.path}-project-#{@group.path}/#{@project["path"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}/#{@project["path"]}] Project was removed")
  end
end
