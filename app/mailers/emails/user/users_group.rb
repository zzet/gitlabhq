class Emails::User::UsersGroup < Emails::User::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = @event.source
    @group        = @up.group
    @member       = @up.user
    @member       = @up.user if @member.is_a?(UsersGroup)

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'joined',
            'X-Gitlab-Source' => 'group-user-relationship',
            'In-Reply-To'     => "group-#{@group.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@member.name}' was added to '#{@group.path}' group")
  end

  def updated_email(notification)
    @notification        = notification
    @event               = @notification.event
    @user                = @event.author
    @upr                 = @event.source
    @group               = @upr.group
    @member              = @upr.user
    data                 = JSON.load(@event.data)
    @changes             = data["previous_changes"]
    unless @changes.blank?
      @previous_permission = Gitlab::Access.options_with_owner.key(@changes["group_access"].first)
      @current_permission  = Gitlab::Access.options_with_owner.key(@changes["group_access"].last)

      headers 'X-Gitlab-Entity' => 'user',
              'X-Gitlab-Action' => 'updated',
              'X-Gitlab-Source' => 'group-user-relationship',
              'In-Reply-To'     => "group-#{@group.path}-user-#{@member.username}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Permissions for user '#{ @member.name }' in group '#{@group.path}' was updated")
    end
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = JSON.load(@event.data)
    @member       = @event.target
    @group        = Group.find(@up["group_id"])
    @member       = User.find(@up["user_id"]) if @member.nil? || @member.is_a?(UsersGroup)

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'left',
            'X-Gitlab-Source' => 'group-user-relationship',
            'In-Reply-To'     => "group-#{@group.path}-user-#{@member.username}"

    if @group
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@member.name}' was removed from '#{@group.path}' group team")
    end
  end
end
