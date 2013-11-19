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
end
