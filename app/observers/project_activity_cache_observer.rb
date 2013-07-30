class ProjectActivityCacheObserver < BaseObserver
  observe :old_event

  def after_create(event)
    if event.project
      event.project.update_column(:last_activity_at, event.created_at)
      if [:pushed, :created_branch, :created_tag, :deleted_branch, :deleted_tag].includes? event.action.to_sym
        event.project.update_column(:last_pushed_at, event.created_at)
      end
    end
  end
end

