class EventObserver < ActiveRecord::Observer
  def after_create(event)
    NotificationService.create_notifications(event)
  end
end
