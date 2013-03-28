class EventObserver < ActiveRecord::Observer
  observe :event

  def after_create(event)
    NotificationService.create_notifications(event)
  end
end
