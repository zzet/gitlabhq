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
          :user_team_user_relationship,
          :users_project,   # +
          :project_hook,    # +
          :system_hook,     # +
          :wiki             # +

  def after_create(model)
    Gitlab::Event::Action.trigger :created, model
  end

  def after_close(moled, transition)
    Gitlab::Event::Action.trigger :closed, model
  end

  def after_reopen(model, transition)
    Gitlab::Event::Action.trigger :reopened, model
  end

  def after_update(model)
    Gitlab::Event::Action.trigger :updated, model
  end

  def after_destroy(model)
    Gitlab::Event::Action.trigger :deleted, model
  end
end
