class ActivityObserver < ActiveRecord::Observer
  observe :issue,           # +
          :key,             # +
          :merge_request,   # +
          :milestone,       # +
          :group,           # +
          :note,            # +
          :project,         # +
          :push,            # +
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
    Gitlab::Event::Action.trigger :closed, model
  end

  def after_reopen(model, transition)
    Gitlab::Event::Action.trigger :reopened, model
  end

  def after_update(model)
    Gitlab::Event::Action.trigger :updated, model unless project_system_update?(model)
  end

  def before_destroy(model)
    Gitlab::Event::Action.trigger :deleted, model
  end

  def project_system_update?(model)
    return false unless model.is_a? ::Project
    return false if model.changes.count != 2
    return true if model.changes[:last_activity_at].present?
  end
end
