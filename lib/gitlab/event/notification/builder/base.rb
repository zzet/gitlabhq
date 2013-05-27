class Gitlab::Event::Notification::Builder::Base

  class << self
    def descendants
      # In production class cache :)
      Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| load f} if super.blank?

      super
    end

    def can_buld?(subscription, event)
      (subscription.user != event.author) || user_subscribed_on_own_changes?(event)
   end

    def build(subscription, event)
      subscription.notifications.create(event: event, subscriber: subscription.user)
    end

    private

    def user_subscribed_on_own_changes?(event)
      event.author.notification_setting && event.author.notification_setting.own_changes)
    end
  end
end
