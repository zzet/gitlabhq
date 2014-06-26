set :host, '10.40.56.97'

role :app, fetch(:host)
role :web, fetch(:host)
role :db,  fetch(:host)

set :branch, 'staging'
set :rails_env, 'staging'

set :deploy_to, '/rest/u/apps/gitlab'
set :bundle_without, %w{development test}.join(' ')
