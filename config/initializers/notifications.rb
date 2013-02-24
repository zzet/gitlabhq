puts "Subscribe"

ActiveSupport::Notifications.subscribe(/gitlab/, EventNotificationWorker)
