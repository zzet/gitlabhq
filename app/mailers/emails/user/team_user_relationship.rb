class Emails::User::TeamUserRelationship < Emails::User::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @source = @event.source
    @tm           = @event.target
    @team         = @utur.team
    @projects     = @team.projects

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'joined',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@tm.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@tm.username}' was added to '#{@team.name}' team")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source
    @member       = @event.target
    @team         = @source.team
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Membership settings for user #{@member.name} in team #{@team.name} was updated")
  end
end
