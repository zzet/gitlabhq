set :rails_env, 'production'
set :branch, 'new_legacy_staging'
#set :branch, 'new_staging'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'

set :db_adapter,     'postgres'
set :bundle_without, %w[development test]

role :web, "192.168.249.67"
role :app, "192.168.249.67"
role :db,  "192.168.249.67", primary: true
