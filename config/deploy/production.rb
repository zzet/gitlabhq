set :host, '10.40.252.13'

role :app, fetch(:host)
role :web, fetch(:host)
role :db,  fetch(:host)

set :branch, 'master'
set :rails_env, 'production'

set :deploy_to, '/rest/u/apps/gitlab'
set :bundle_without, %w{staging development test}.join(' ')
