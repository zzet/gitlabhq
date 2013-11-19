class Emails::Group::Group < Emails::Group::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New group '#{@group.name}' was created")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group.name}' was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @group        = data

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group["path"]}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group["name"]}' was deleted")
  end
end
