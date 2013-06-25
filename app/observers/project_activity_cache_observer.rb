class ProjectActivityCacheObserver < BaseObserver
  observe :old_event

  def after_create(event)
    event.project.update_column(:last_activity_at, event.created_at) if event.project
  end
end

