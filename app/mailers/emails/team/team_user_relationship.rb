class Emails::Team::TeamUserRelationship < Emails::Team::Base
  def joined_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @event.source
    @team         = @event.target
    @member       = @utur.user
    @projects     = @team.projects

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'joined',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@member.name}' was added to '#{@team.name}' team")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @event.source
    @team         = @event.target
    @member       = @utur.user
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Membership settings for user '#{@member.name}' in team '#{@team.name}' was updated")
  end

  def left_email(notification)
    @notification = notification
    @event        = @notification.event
    @up           = JSON.load(@event.data)
    @user         = @event.author
    @team         = @event.target
    @member       = User.find(@up["user_id"])

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'left',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@member.username}"

    if @team && @member
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@member.name}' was removed from '#{@team.name}' team")
    end
  end
end
