class Emails::Group::TeamGroupRelationship < Emails::Group::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utgr         = @event.source
    @group        = @event.target
    @team         = @utgr.team

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'team-group-relationship',
            'In-Reply-To'     => "group-#{@group.path}-team-group-relationship-#{@utgr.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was assigned to '#{@group.name}' group")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = JSON.load(@event.data).to_hash
    @team         = Team.find(@source["team_id"])
    @group        = @event.target

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'resigned',
            'X-Gitlab-Source' => 'team-group-relationship',
            'In-Reply-To'     => "team-#{@team.path}-group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was resigned from '#{@group.name}' group")
  end
end
