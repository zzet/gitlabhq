ActiveSupport::Notifications.subscribe(/gitlab/, EventSubscriptionCreateWorker)
ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker)
ActiveSupport::Notifications.subscribe(/gitlab/, EventSubscriptionCleanWorker)
