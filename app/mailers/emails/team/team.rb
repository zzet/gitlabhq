class Emails::Team::Team < Emails::Team::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source

    set_x_gitlab_headers(:team, :team, :created, "team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New team '#{@team.name}' was created")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:team, :team, :updated, "team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @team         = data

    set_x_gitlab_headers(:team, :team, :deleted, "team-#{@team['path']}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team['name']}' was removed")
  end

  def members_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @members  = @team.team_user_relationships.where(user_id: @events.pluck(:target_id))

    set_x_gitlab_headers(:team, :team, :members_added, "team-#{@team.path}-members")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "#{@events.count} users were added to team '#{@team.path}'")
  end

  def projects_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Project)
    @projects     = Project.where(id: @events.pluck(:target_id))

    set_x_gitlab_headers(:team, :team, :projects_added, "team-#{@team.path}-projects")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@team.path}' team was assigned on #{@events.count} projects")
  end

  def groups_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Group)
    @groups       = Group.where(id: @events.pluck(:target_id))

    set_x_gitlab_headers(:team, :team, :groups_added, "team-#{@team.path}-groups")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@team.path}' team was assigned on #{@events.count} groups")
  end
end
