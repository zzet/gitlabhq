class ProjectActivityCacheObserver < BaseObserver
  observe :old_event

  def after_create(event)
    if event.project
      event.project.update_column(:last_activity_at, event.created_at)
      event.project.update_column(:last_pushed_at, event.created_at) if event.action = 5
    end
  end
end

