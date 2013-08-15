class ActivityObserver < ActiveRecord::Observer
  observe :issue,           # +
          :key,             # +
          :merge_request,   # +
          :milestone,       # +
          :group,           # +
          :note,            # +
          :project,         # +
          :protected_branch,# +
          :service,         # +
          :snippet,         # +
          :user,            # +
          :user_team,       # +
          :user_team_project_relationship,
          :user_team_group_relationship,
          :user_team_user_relationship,
          :users_project,   # +
          :project_hook,    # +
          :system_hook

  def after_create(model)
    Gitlab::Event::Action.trigger :created, model
  end

  def after_close(model, transition)
    EventHierarchyWorker.reset
    Gitlab::Event::Action.trigger :closed, model
  end

  def after_block(model, transition)
    EventHierarchyWorker.reset
    Gitlab::Event::Action.trigger :blocked, model
  end

  def after_activate(model, transition)
    EventHierarchyWorker.reset
    Gitlab::Event::Action.trigger :activate, model
  end

  def after_merge(model, transition)
    EventHierarchyWorker.reset
    Gitlab::Event::Action.trigger :merged, model
  end

  def after_reopen(model, transition)
    EventHierarchyWorker.reset
    Gitlab::Event::Action.trigger :reopened, model
  end

  def after_update(model)
    Gitlab::Event::Action.trigger :updated, model unless updated_by_system?(model)
  end

  def before_destroy(model)
    Gitlab::Event::Action.trigger :deleted, model
  end

  def updated_by_system?(model)
    project_system_update?(model) || user_system_update?(model)
  end

  def project_system_update?(model)
    return false unless model.is_a? ::Project
    return false if model.changes.count != 2
    return true if model.changes[:last_activity_at].present?
    return true if model.changes[:last_pushed_at].present?
    false
  end

  def user_system_update?(model)
    return false unless model.is_a? ::User
    return false if model.changes.count != 4
    return true if model.changes[:last_sign_in_at].present?
    false
  end
end
