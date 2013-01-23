set :stages, %w(production staging)
set :default_stage, "staging"

require 'capistrano/ext/multistage'
require 'capi/unicorn'
require 'airbrake/capistrano'
require 'rake'

set :application, "gitlab"
set :rvm_type, :system

set :scm, :git
set :repository, "git://github.com/Undev/gitlabhq.git"# "git@gitlab.home:gitlabhq.git"

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
end

before 'deploy:finalize_update',
       'deploy:symlink_db',
       'deploy:symlink_gitlab',
       #'deploy:symlink_resque',
       'deploy:symlink_unicorn'
after "deploy:restart", "unicorn:stop"
after "deploy:update", "deploy:cleanup"

