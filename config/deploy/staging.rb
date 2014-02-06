set :rails_env, "staging"
set :branch, 'staging'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'

set :db_adapter,     'postgres'
#set :bundle_without, %w[development test] + (%w[mysql postgres] - [db_adapter])
set :bundle_without, %w[development] + (%w[mysql postgres] - [db_adapter])

role :web, "10.40.56.97"
role :app, "10.40.56.97"
role :db,  "10.40.56.97", :primary => true

after "deploy:update_code", "deploy:migrate"
after "deploy:update", "deploy:cleanup"
