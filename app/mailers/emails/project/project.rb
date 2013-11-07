class Emails::Project::Project < Emails::Project::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was created")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @project      = data
    @namespace    = Namespace.find_by_id(@project["namespace_id"])

    if @namespace
      headers 'X-Gitlab-Entity' => 'project',
        'X-Gitlab-Action' => 'deleted',
        'X-Gitlab-Source' => 'project',
        'In-Reply-To'     => "project-#{@namespace.path}/#{@project["path"]}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@namespace.path}/#{@project["path"]}] Project was removed")
    end
  end

  def transfer_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @project        = @event.source
    @owner_changes  = JSON.load(@event.data).to_hash["owner_changes"]["namespace_id"]
    @old_owner      = Namespace.find(@owner_changes.first)
    @new_owner      = Namespace.find(@owner_changes.last)

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'transfer',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "project-#{@old_owner.path}/#{@project.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@old_owner.path}/#{@project.path}] Project was moved from '#{@old_owner.path}' to '#{@new_owner.path}' namespace [transfered]")
  end
end