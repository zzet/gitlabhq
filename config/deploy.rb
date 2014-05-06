require 'rake'
require 'undev/capistrano'

set :stages, %w(production staging)
set :default_stage, "staging"

#set :domain,         'set application domain here'
set :db_adapter,     'postgres' # or mysql
set :mount_point,    '/'
set :application,    'gitlabhq'
set :user,           'git'
set :rails_env,      'production'
set :deploy_to,      "/home/#{user}/apps/#{application}"
set :bundle_without, %w[development test] + (%w[mysql postgres] - [db_adapter])
set :asset_env,      "RAILS_GROUPS=assets RAILS_RELATIVE_URL_ROOT=#{mount_point.sub(/\/+\Z/, '')}"

set :application, "gitlab"
set :undev_ruby_version, '2.0.0-p247'

set :scm, :git
set :repository, "git://git.undev.cc/infrastructure/gitlab.git"

set :use_sudo, false
set :ssh_options, :forward_agent => true
default_run_options[:pty] = true

namespace :deploy do
  desc "Symlinks the database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{release_path}/config/database.yml.undev #{release_path}/config/database.yml"
  end
  desc "Seed database data"
  task :seed_data do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} #{rake} db:seed"
  end
  desc "Symlinks the gitlab.yml"
  task :symlink_gitlab, :roles => :app do
    run "ln -nfs #{release_path}/config/gitlab.yml.undev #{release_path}/config/gitlab.yml"
  end
  desc "Symlinks the resque.yml"
  task :symlink_resque, :roles => :app do
    run "ln -nfs #{release_path}/config/resque.yml.undev #{release_path}/config/resque.yml"
  end
  desc "Symlinks the unicorn.rb"
  task :symlink_unicorn, :roles => :app do
    run "ln -nfs #{release_path}/config/unicorn.rb.undev #{release_path}/config/unicorn.rb"
  end

  desc "Symlinks the puma.rb"
  task :symlink_puma, :roles => :app do
    run "ln -nfs #{release_path}/config/puma.rb.undev #{release_path}/config/puma.rb"
  end

  desc <<-DESC
    Send a USR2 to the unicorn process to restart for zero downtime deploys.
      runit expects 2 to tell it to send the USR2 signal to the process.
  DESC
  task :restart, :roles => :app, :except => { :no_release => true } do
    #FIX react-rails generate js in each rails start up
    #rake tasks generate js with 664 and gitlab owner
    #unicorn start under git user, which can't overwrite js
    run "chmod 664 #{release_path}/tmp/react-rails/*"
    run "sudo sv restart /etc/service/gitlab-sidekiq-*"
    run "sudo sv restart /etc/service/gitlab-web-*"
  end
end

before 'deploy:finalize_update',
  'deploy:symlink_db',
  'deploy:symlink_gitlab',
  'deploy:symlink_resque',
  'deploy:symlink_puma',
  'deploy:symlink_unicorn'
#after "deploy:restart", "unicorn:stop"
#after "deploy:reload"
after "deploy:update", "deploy:cleanup"
