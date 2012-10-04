set :rails_env, :production
set :branch, 'staging'
set :user, 'gitlab_staging'
set :keep_releases, 5

role :web, "10.40.37.207"
role :app, "10.40.37.207"
role :db,  "10.40.37.207", :primary => true
