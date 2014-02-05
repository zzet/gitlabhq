ActiveSupport::Notifications.subscribe(/gitlab/, EventSubscriptionCreateWorker)
ActiveSupport::Notifications.subscribe(/gitlab/, EventHierarchyWorker)
ActiveSupport::Notifications.subscribe(/gitlab/, Gitlab::Event::Factory)
ActiveSupport::Notifications.subscribe(/gitlab/, EventSubscriptionCleanWorker)
