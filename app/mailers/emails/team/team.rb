class Emails::Team::Team < Emails::Team::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New team '#{@team.name}' was created")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @team         = data

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team["path"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team['name']}' was removed")
  end

  def members_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @members  = @team.team_user_relationships.where(user_id: @events.pluck(:target_id))

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'members_added',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}-members"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "#{@events.count} users were added to team '#{@team.path}'")
  end

  def projects_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Project)
    @projects     = Project.where(id: @events.pluck(:target_id))

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'projects_added',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}-projects"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@team.path}' team was assigned on #{@events.count} projects")
  end

  def groups_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Group)
    @groups       = Group.where(id: @events.pluck(:target_id))

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'groups_added',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}-teams"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@team.path}' team was assigned on #{@events.count} groups")
  end
end
