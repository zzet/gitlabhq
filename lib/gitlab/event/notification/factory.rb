class Gitlab::Event::Notification::Factory

  class << self
    def build(subscription, event)
      notifications = []

      builder = builder_for(event)

      notifications = builder.build(subscription, event) if builder.can_build?(subscription, event)

      notifications.flatten
    end

    def create_notifications(event)
      if can_create_notifications?(event)
        notifications = []
        subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source_type)

        subscriptions.each do |subscription|
          # Not send notification about changes to changes author
          # TODO. Rewrite in future with check by Entity type
          notifications += build(subscription, event)
        end

        notifications.each do |notification|
          notification.save
        end
      end
    end

    def can_create_notifications?(event)
      event.deleted_related? || event.deleted_self? || event.push_event? || event.full?
      # (event.target || event.action.to_sym == :deleted) && ((::Event::Action.push_action?(event.action)) || event.source_type)
    end

    def builder_for(event)
      builder = source_with_action_builder(event)
      builder ||= source_builder(event)
      builder ||= default_builder(event)

      builder
    end

    private

    def source_with_action_builder(event)
      klass = "Gitlab::Event::Notification::Builder::#{event.source_type.to_s}#{event.action.camelize}"
      klass = klass.constantize

      klass.new
    rescue NameError
      nil
    end

    def source_builder(event)
      klass = "Gitlab::Event::Notification::Builder::#{event.source_type.to_s}"
      klass = klass.constantize

      klass.new
    rescue NameError
      nil
    end

    def default_builder(event)
      Gitlab::Event::Notification::Builder::Default.new
    end
  end
end
