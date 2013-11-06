class Emails::User::Key < Emails::User::Base
  def added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @key          = @event.source
    @updated_user = @event.target

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'key',
            'In-Reply-To'     => "user-#{@updated_user.username}-key-#{@key.title}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Key '#{@key.title}' was added to '#{@updated_user.name}' profile")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @key          = @event.source
    @updated_user = @event.target
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'key',
            'In-Reply-To'     => "user-#{@updated_user.username}-key-#{@key.title}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Key '#{@key.title}' was updated in #{@updated_user.name} profile")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @key          = @source = JSON.load(@event.data).to_hash
    @updated_user = @event.target

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'deleted',
            'X-Gitlab-Source' => 'key',
            'In-Reply-To'     => "user-#{@updated_user.username}-key-#{@key['title']}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Key #{@key["title"]} was deleted from #{@updated_user.name} profile")
  end
end
