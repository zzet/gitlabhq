class Emails::Team::TeamGroupRelationship < Emails::Team::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utgr         = @event.source
    @team         = @event.target
    @group        = @utgr.group

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'team-group-relationship',
            'In-Reply-To'     => "team-#{@team.path}-team-group-relationship-#{@utgr.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was assigned to '#{@group.name}' group")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = JSON.load(@event.data).to_hash
    @group        = Group.find(@source["group_id"])
    @team         = @event.target

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'left',
            'X-Gitlab-Source' => 'team-group-relationship',
            'In-Reply-To'     => "team-#{@team.path}-group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was resigned from '#{@group.name}' group")
  end
end
