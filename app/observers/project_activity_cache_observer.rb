class ProjectActivityCacheObserver < ActiveRecord::Observer
  observe :event

  def after_create(event)
    event.project.update_attribute(:last_activity_at, event.created_at) if event.project
  end
end

