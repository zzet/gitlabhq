class Interactor::Base
  include Interactor

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

  def reindex_with_elastic(klass, id, action = :update)
    begin
      Elastic::BaseIndexer.perform_async(action, klass.name, id)
    rescue
    end
  end

  def multiple_action(action_name, action_source, source, items = nil, &block)
    RequestStore.store[:borders] ||= []

    if [items].flatten.many? || items.nil?
      RequestStore.store[:borders].push("gitlab.#{action_name}.#{action_source}")
      Gitlab::Event::Action.trigger :"#{action_name}", source
    end

    yield

    if [items].flatten.many? || items.nil?
      RequestStore.store[:borders].pop
    end

    receive_delayed_notifications
  end

  def log_info message
    Gitlab::AppLogger.info message
  end

  def error(message)
    {
      message: message,
      status: :error
    }
  end

  def success(message = "")
    {
      message: message,
      status: :success
    }
  end
end
