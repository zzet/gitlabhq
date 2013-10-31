set :rails_env, "production"
set :branch, 'staging'
set :user, 'gitlab'
set :keep_releases, 5
set :deploy_to, '/rest/u/apps/gitlab'

set :db_adapter,     'postgres'
set :bundle_without, %w[development test] + (%w[mysql postgres] - [db_adapter])

role :web, "10.40.56.97"
role :app, "10.40.56.97"
role :db,  "10.40.56.97", :primary => true

namespace :deploy do
  desc "Generate mails"
  task :generate_mails, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=test bundle exec rake db:migrate"
    run "cd #{current_path}/tmp/ && ls . | grep -i \"^repositories\" | xargs rm -rf"
    run "cd #{current_path} && mkdir #{current_path}/tmp/repositories/"
    run "tar -xvf #{current_path}/spec/seed_project.tar.gz -C #{current_path}/tmp/repositories/"
    begin
      run "cd #{current_path} && RAILS_ENV=test bundle exec rspec spec/mailers/event_notification_mailer_spec.rb"
    rescue
      true
    end
    run "cd #{current_path}/freezed_emails/ && ls . | egrep -v \"^gitlab\" | xargs rm"
  end
end

after "deploy:update_code", "deploy:migrate"
after "deploy:update", "deploy:cleanup"#, "deploy:generate_mails"
