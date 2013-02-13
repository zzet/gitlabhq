class ActivityObserver < ActiveRecord::Observer
  observe :key, :milestone, :namespace, :note, 
    :project, :protected_branch, :service, 
    :snippet, :user, :user_team, :user_team_project_relationship, 
    :user_team_user_relationship, :users_project, :web_hook, :wiki

end
