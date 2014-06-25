# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'gitlab'
set :user, 'gitlab'

set :scm, :git
set :repo_url, 'git://git.undev.cc/infrastructure/gitlab.git'

set :ssh_options, { user: fetch(:user), forward_agent: true }

set :keep_releases, 5
set :deploy_to, "/rest/u/apps/#{fetch(:application)}"

set :format, :pretty
set :log_level, :debug

set :undev_ruby_version, 'ruby-2.0.0-p247'
set :default_env, { path: "/opt/#{fetch(:undev_ruby_version)}/bin/:$PATH" }

set :linked_dirs, %w(log pids tmp public/assets)

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

set :pty, true

SSHKit.config.command_map[:sv_restart] = 'sudo sv -w 30 restart'

set :unicorn_web_service, "/etc/service/gitlab-web-unicorn"
set :unicorn_api_service, "/etc/service/gitlab-web-unicorn_api"
set :faye_service,         "/etc/service/gitlab-web-faye"

set :sidekiq_main_service, "/etc/service/gitlab-sidekiq-main"
set :sidekiq_mail_service, "/etc/service/gitlab-sidekiq-mail"
set :sidekiq_gitshell_service, "/etc/service/gitlab-sidekiq-gitshell"
set :sidekiq_elasticsearch_service, "/etc/service/gitlab-sidekiq-elasticsearch"

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :rake do
  desc 'Run rake task on remote server'
  task :invoke do
    on roles :all do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "#{ENV['task']}"
        end
      end
    end
  end
end

namespace :deploy do
  namespace :symlink_config do
    desc 'Symlinks the database.yml'
    task :db do
      on roles :app do
        execute "ln -nfs #{release_path}/config/database.yml.undev #{release_path}/config/database.yml"
      end
    end

    desc 'Symlinks the gitlab.yml'
    task :gitlab do
      on roles :app do
        execute "ln -nfs #{release_path}/config/gitlab.yml.undev #{release_path}/config/gitlab.yml"
      end
    end

    desc 'Symlinks the resque.yml'
    task :resque do
      on roles :app do
        execute "ln -nfs #{release_path}/config/resque.yml.undev #{release_path}/config/resque.yml"
      end
    end

    desc 'Symlinks the unicorn.rb'
    task :unicorn do
      on roles :app do
        execute "ln -nfs #{release_path}/config/unicorn.rb.undev #{release_path}/config/unicorn.rb"
      end
    end

    desc 'Symlinks the puma.rb'
    task :puma do
      on roles :app do
        execute "ln -nfs #{release_path}/config/puma.rb.undev #{release_path}/config/puma.rb"
      end
    end
  end

  namespace :web do
    desc 'Restart web'
    task :restart do
      on roles :app do
				execute "chmod -R 0775 #{release_path}/tmp/"
        if test "[ -L #{fetch(:unicorn_web_service)} ]"
          execute :sv_restart, fetch(:unicorn_web_service)
        end

        if test "[ -L #{fetch(:unicorn_api_service)} ]"
          execute :sv_restart, fetch(:unicorn_api_service)
        end

        if test "[ -L #{fetch(:faye_service)} ]"
          execute :sv_restart, fetch(:faye_service)
        end
      end
    end
  end

  namespace :queue do
    desc 'Restart sidekiq'
    task :restart do
      on roles :app do
        if test "[ -L #{fetch(:sidekiq_main_service)} ]"
          execute :sv_restart, fetch(:sidekiq_main_service)
        end

        if test "[ -L #{fetch(:sidekiq_mail_service)} ]"
          execute :sv_restart, fetch(:sidekiq_mail_service)
        end

        if test "[ -L #{fetch(:sidekiq_gitshell_service)} ]"
          execute :sv_restart, fetch(:sidekiq_gitshell_service)
        end

        if test "[ -L #{fetch(:sidekiq_elasticsearch_service)} ]"
          execute :sv_restart, fetch(:sidekiq_elasticsearch_service)
        end
      end
    end
  end

  after 'deploy:updating', 'deploy:symlink_config:db'
  after 'deploy:updating', 'deploy:symlink_config:gitlab'
  after 'deploy:updating', 'deploy:symlink_config:resque'
  after 'deploy:updating', 'deploy:symlink_config:unicorn'

  after 'finishing', 'deploy:web:restart'
  after 'finishing', 'deploy:queue:restart'
#  after 'finishing', 'airbrake:deploy'
end
