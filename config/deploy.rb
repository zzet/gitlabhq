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

set :linked_dirs, %w(log pids tmp public/assets public/uploads public/system)

set :pty, true

SSHKit.config.command_map[:sv_restart] = 'sudo sv -w 30 restart'
SSHKit.config.command_map[:sv_force_restart] = 'sudo sv force-restart'

set :unicorn_web_service, "/etc/service/gitlab-web-unicorn"
set :unicorn_api_service, "/etc/service/gitlab-web-unicorn_api"
set :faye_service,         "/etc/service/gitlab-web-faye"

set :resque_main_service, "/etc/service/gitlab-resque-main"
set :resque_mail_service, "/etc/service/gitlab-resque-mail"
set :resque_gitshell_service, "/etc/service/gitlab-resque-gitshell"
set :resque_elasticsearch_service, "/etc/service/gitlab-resque-elasticsearch"

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
  namespace :maintenance do
    desc "Enable maintenance mode"
    task :enable do
      on roles :app do
        execute "ln -nfs #{release_path}/public/gitlab_logo.png #{current_path}/public/assets/gitlab_logo.png"
        execute "ln -nfs #{release_path}/public/static.css #{current_path}/public/assets/static.css"
        execute "ln -nfs #{release_path}/public/deploy.html #{current_path}/public/maintenance.html"
      end
    end

    desc "Disable maintenance mode"
    task :disable do
      on roles :app do
        execute "rm #{current_path}/public/maintenance.html"
        execute "rm #{current_path}/public/assets/gitlab_logo.png"
        execute "rm #{current_path}/public/assets/static.css"
      end
    end
  end

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
      end
    end

    desc 'Restart faye'
    task :faye_restart do
      on roles :app do
        if test "[ -L #{fetch(:faye_service)} ]"
          execute :sv_force_restart, fetch(:faye_service), raise_on_non_zero_exit: false
        end
      end
    end
  end

  namespace :queue do
    desc 'Restart resque'
    task :restart do
      on roles :app do
        if test "[ -L #{fetch(:resque_main_service)} ]"
          execute :sv_restart, fetch(:resque_main_service)
        end

        if test "[ -L #{fetch(:resque_mail_service)} ]"
          execute :sv_restart, fetch(:resque_mail_service)
        end

        if test "[ -L #{fetch(:resque_gitshell_service)} ]"
          execute :sv_restart, fetch(:resque_gitshell_service)
        end

        if test "[ -L #{fetch(:resque_elasticsearch_service)} ]"
          execute :sv_restart, fetch(:resque_elasticsearch_service)
        end
      end
    end
  end

  before 'deploy:starting', 'deploy:maintenance:enable'

  after 'deploy:updating', 'deploy:symlink_config:db'
  after 'deploy:updating', 'deploy:symlink_config:gitlab'
  after 'deploy:updating', 'deploy:symlink_config:resque'
  after 'deploy:updating', 'deploy:symlink_config:unicorn'

  after 'finishing', 'deploy:web:restart'
  after 'finishing', 'deploy:web:faye_restart'
  after 'finishing', 'deploy:queue:restart'
#  after 'finishing', 'airbrake:deploy'
  #after 'finishing', 'deploy:maintenance:disable'
end
