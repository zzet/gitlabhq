ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker)
ActiveSupport::Notifications.subscribe(/gitlab/, EventSubscriptionWorker)
