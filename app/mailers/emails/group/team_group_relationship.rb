class Emails::Group::TeamGroupRelationship < Emails::Group::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utgr         = @event.source
    @group        = @utgr.group
    @team         = @utgr.team

    set_x_gitlab_headers(:group, 'team-group-relationship', :assigned, "group-#{@group.path}-team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was assigned to '#{@group.name}' group")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.data
    @team         = Team.find(@source["team_id"])
    @group        = Group.find(@source["group_id"])

    set_x_gitlab_headers(:group, 'team-group-relationship', :resigned, "group-#{@group.path}-team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was resigned from '#{@group.name}' group")
  end
end
