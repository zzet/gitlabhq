module Emails
  module Groups
    def group_access_granted_email(user_group_id)
      @membership = UsersGroup.find(user_group_id)
      @group = @membership.group

      mail(to: @membership.user.email,
           subject: subject("access to group was granted"))
    end

    #
    # Group self action
    #
    def created_group_email(notification)
      @notification = notification
      @event        = @notification.event
      @user         = @event.author
      @group        = @event.source

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'created',
              'X-Gitlab-Source' => 'group',
              'In-Reply-To'     => "group-#{@group.path}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New group '#{@group.name}' was created")
    end

    def updated_group_email(notification)
      @notification = notification
      @event        = @notification.event
      @user         = @event.author
      @group        = @event.source
      @changes      = JSON.load(@event.data).to_hash["previous_changes"]

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'updated',
              'X-Gitlab-Source' => 'group',
              'In-Reply-To'     => "group-#{@group.path}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group.name}' was updated")
    end

    def deleted_group_email(notification)
      @notification = notification
      @event        = @notification.event
      data          = JSON.load(@event.data).to_hash
      @user         = @event.author
      @group        = data

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'deleted',
              'X-Gitlab-Source' => 'group',
              'In-Reply-To'     => "group-#{@group["path"]}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group["name"]}' was deleted")
    end

    def updated_project_email(notification)
      @notification = notification
      @event        = @notification.event
      @user         = @event.author
      @project      = @event.source
      @group        = @event.target
      @changes      = JSON.load(@event.data).to_hash["previous_changes"]

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'updated',
              'X-Gitlab-Source' => 'project',
              'In-Reply-To'     => "project-#{@project.path_with_namespace}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was updated")
    end

  def deleted_group_project_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @project      = data
    @group        = @event.target

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "group-#{@group.path}-project-#{@group.path}/#{@project["path"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}/#{@project["path"]}] Project was removed")
  end


  def updated_group_users_group_email(notification)
    @notification         = notification
    @event                = @notification.event
    @user                 = @event.author
    @upr                  = @event.source
    data                  = JSON.load(@event.data)
    @group                = Group.find(data["group_id"])
    @member               = User.find(data["user_id"])
    @changes              = data["previous_changes"]
    unless @changes.blank?
      @previous_permission  = UsersGroup.access_roles.key(@changes["group_access"].first)
      @current_permission   = UsersGroup.access_roles.key(@changes["group_access"].last)

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'updated',
              'X-Gitlab-Source' => 'group-user-relationship',
              'In-Reply-To'     => "group-#{@group.path_with_namespace}-user-#{@member.username}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path_with_namespace}] Permissions for user '#{ @member.name }' was updated")
    end
  end

  end
end
