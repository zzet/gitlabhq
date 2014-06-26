class Emails::Team::TeamGroupRelationship < Emails::Team::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utgr         = @event.source
    @team         = @utgr.team
    @group        = @utgr.group

    set_x_gitlab_headers(:team, 'team-group-relationship', :assigned, "team-#{@team.path}-group-#{@group.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' assignation to '#{@group.name}' group")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.data
    @group        = Group.find_by_id(@source["group_id"])
    @team         = Team.find_by_id(@source["team_id"])

    if @team && @group
      set_x_gitlab_headers(:team, 'team-group-relationship', :resigned, "team-#{@team.path}-group-#{@group.path}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' assignation to '#{@group.name}' group")
    end
  end
end
