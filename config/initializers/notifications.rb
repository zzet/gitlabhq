ActiveSupport::Notifications.subscribe(/gitlab/, EventSubscriptionWorker)
ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker)
