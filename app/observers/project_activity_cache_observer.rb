class ProjectActivityCacheObserver < BaseObserver
  observe :event

  def after_create(event)
    project.update_attribute(:last_activity_at, event.created_at)
  end
end

