set :user, 'gitlab_production'
set :rails_env, 'production'

role :db,  "10.40.37.207", primary: true
role :app, "10.40.37.207"
role :web, "10.40.37.207"

set :branch, "master"
set :deploy_to, "/u/apps/gitlab"
