set :rails_env, "staging"
set :branch, 'staging'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'

set :db_adapter,     'postgres'
set :bundle_without, %w[development] + (%w[mysql postgres] - [db_adapter])

role :web, "10.40.42.123"
role :app, "10.40.42.123"
role :db,  "10.40.42.123", :primary => true

namespace :deploy do
  desc "Generate mails"
  task :generate_mails, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=test bundle exec rspec spec/mailers/event_notification_mailer_spec.rb"
  end
end

after "deploy:update", "deploy:cleanup", "deploy:generate_mails"
