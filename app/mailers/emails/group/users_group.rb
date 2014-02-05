class Emails::Group::UsersGroup < Emails::Group::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @ug           = @event.source
    @group        = @event.target
    @member       = @ug.user
    @group        = @ug.group if @group.is_a?(UsersGroup)

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'joined',
            'X-Gitlab-Source' => 'group-user-relationship',
            'In-Reply-To'     => "group-#{@group.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] '#{ @member.name }' membership in group")
  end

  def updated_email(notification)
    @notification         = notification
    @event                = @notification.event
    @user                 = @event.author
    @upr                  = @event.source
    data                  = JSON.load(@event.data)
    @group                = Group.find_by_id(data["group_id"])
    @member               = User.find_by_id(data["user_id"])
    @changes              = data["previous_changes"]
    unless @changes.blank?
      @previous_permission  = Gitlab::Access.options_with_owner.key(@changes["group_access"].first)
      @current_permission   = Gitlab::Access.options_with_owner.key(@changes["group_access"].last)

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'updated',
              'X-Gitlab-Source' => 'group-user-relationship',
              'In-Reply-To'     => "group-#{@group.path}-user-#{@member.username}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] '#{ @member.name }' membership in group")
    end
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @ug           = JSON.load(@event.data)
    @group        = @event.target
    @member       = User.find_by_id(@ug["user_id"])
    @group        = Group.find_by_id(@ug["group_id"]) if @group.nil? || @group.is_a?(UsersGroup)

    if @member && @group
    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'left',
            'X-Gitlab-Source' => 'group-user-relationship',
            'In-Reply-To'     => "group-#{@group.path}-user-#{@member.username}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] '#{ @member.name }' membership in group")
    end
  end
end
