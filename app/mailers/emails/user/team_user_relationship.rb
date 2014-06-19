class Emails::User::TeamUserRelationship < Emails::User::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @event.source
    @member       = @utur.user
    @team         = @utur.team
    @projects     = @team.projects

    set_x_gitlab_headers(:user, 'team-user-relationship', :joined, "user-#{@member.username}-team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@member.username}' membership in '#{@team.name}' team")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source
    @member       = @source.user
    @team         = @source.team
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:user, 'team-user-relationship', :updated, "user-#{@member.username}-team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@member.username}' membership in '#{@team.name}' team")
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @up           = @event.data
    @member       = @event.target
    @team         = Team.find_by_id(@up["team_id"])
    @member       = User.find_by_id(@up["user_id"]) if @member.nil? || @member.is_a?(TeamUserRelationship)

    if @team && @member
      set_x_gitlab_headers(:user, 'team-user-relationship', :left, "user-#{@member.username}-team-#{@team.path}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "'#{@member.username}' membership in '#{@team.name}' team")
    end
  end
end
