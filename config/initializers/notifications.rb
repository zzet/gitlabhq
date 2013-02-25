ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker)
