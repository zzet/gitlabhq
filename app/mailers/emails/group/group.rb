class Emails::Group::Group < Emails::Group::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source

    set_x_gitlab_headers(:group, :group, :created, "group-#{@group.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New group '#{@group.name}' was created")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:group, :group, :updated, "group-#{@group.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group.name}' was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @group        = data

    set_x_gitlab_headers(:group, :group, :deleted, "group-#{@group['path']}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group["name"]}' was deleted")
  end

  def members_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @new_members  = @group.users_groups.where(user_id: @events.pluck(:target_id))

    set_x_gitlab_headers(:group, :group, :members_added, "group-#{@group.path}-members")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] #{@events.count} were added to group team")
  end

  def teams_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Team)
    @teams        = Team.where(id: @events.pluck(:target_id))

    set_x_gitlab_headers(:group, :group, :teams_added, "group-#{@group.path}-teams")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@group.path}] #{@events.count} teams were assigned on group")
  end
end
