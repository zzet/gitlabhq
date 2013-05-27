class Gitlab::Event::Notifications::Factory

  class << self
    def build(subscription, event)
      notifications = []

      Gitlab::Event::Notification::Builder::Base.descendants.each do |descendant|
        notifications << descendant.build(subscription, event) if descendant.can_build?(subscription, event)
      end

      notifications.flatten
    end

    def create_notifications(event)
      if can_create_notifications?(event)
        subscriptions = ::Event::Subscription.by_target(event.target).by_source_type(event.source_type)

        subscriptions.each do |subscription|
          # Not send notification about changes to changes author
          # TODO. Rewrite in future with check by Entity type
          notifications = self.build(subscription, event)
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
  end
end
