class Emails::Team::TeamUserRelationship < Emails::Team::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @event.source
    @team         = @utur.team
    @member       = @utur.user
    @projects     = @team.projects
    @permission   = Gitlab::Access.options_with_owner.key(@utur.team_access)

    set_x_gitlab_headers(:team, 'team-user-relationship', :joined, "team-#{@team.path}-user-#{@member.username}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@member.name}' membership in '#{@team.name}' team")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @event.source
    @team         = @utur.team
    @member       = @utur.user
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:team, 'team-user-relationship', :updated, "team-#{@team.path}-user-#{@member.username}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@member.name}' membership in '#{@team.name}' team")
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @up           = @event.data
    @user         = @event.author
    @team         = Team.find_by_id(@up["team_id"])
    @member       = User.find_by_id(@up["user_id"])

    if @team && @member
      set_x_gitlab_headers(:team, 'team-user-relationship', :left, "team-#{@team.path}-user-#{@member.username}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@member.name}' membership in '#{@team.name}' team")
    end
  end
end
