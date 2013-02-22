set :rails_env, "production"
set :branch, 'new_staging'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'

set :db_adapter,     'postgres'
set :bundle_without, %w[development test] + (%w[mysql postgres] - [db_adapter])

role :web, "10.40.42.123"
role :app, "10.40.42.123"
role :db,  "10.40.42.123", :primary => true
