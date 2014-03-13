class Emails::Group::Group < Emails::Group::Base
  def created_email(notification)
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

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @changes      = @event.data["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group.name}' was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @group        = data

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group["path"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group["name"]}' was deleted")
  end

  def members_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @new_members  = @group.users_groups.where(user_id: @events.pluck(:target_id))

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'members_added',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}-members"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] #{@events.count} were added to group team")
  end

  def teams_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Team)
    @teams        = Team.where(id: @events.pluck(:target_id))

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'teams_added',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}-teams"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] #{@events.count} teams were assigned on group")
  end
end
