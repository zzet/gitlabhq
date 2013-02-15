class ActivityObserver < ActiveRecord::Observer
  observe :key, :milestone, :namespace, :note,
    :project, :protected_branch, :service,
    :snippet, :user, :user_team, :user_team_project_relationship,
    :user_team_user_relationship, :users_project, :web_hook, :wiki

  def after_create(model)
    # trigger action
  end

  def after_update(model)
    # trigger action
  end

  def after_destroy(model)
    # trigger action
  end
end
