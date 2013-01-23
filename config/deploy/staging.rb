set :rails_env, "production"
set :branch, 'staging'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'

role :web, "10.40.42.123"
role :app, "10.40.42.123"
role :db,  "10.40.42.123", :primary => true
