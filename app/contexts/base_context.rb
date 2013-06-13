class BaseContext
  attr_accessor :current_user, :params

  def initialize(project, user, params)
    @current_user, @params = user, params.dup
  end

  def abilities
    @abilities ||= begin
                     abilities = Six.new
                     abilities << Ability
                     abilities
                   end
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def receive_delayed_notifications
    notifications = Event::Subscription::Notification.delayed
    notifications.each do |notification|
      Sidekiq::Client.enqueue_to(:mail_notifications, MailNotificationWorker, notification.id)
    end
  end
end
