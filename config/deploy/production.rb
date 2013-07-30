set :rails_env, 'production'
set :branch, 'master'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'
set :rvm_ruby_string, 'ruby-1.9.3-p194@gitlab'

set :db_adapter,     'postgres'
set :bundle_without, %w[staging development test] + (%w[mysql postgres] - [db_adapter])

role :web, "10.40.252.13"
role :app, "10.40.252.13"
role :db,  "10.40.252.13", primary: true
