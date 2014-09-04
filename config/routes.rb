require 'api/api'
require 'resque/scheduler/server'

Gitlab::Application.routes.draw do
  #
  # Search
  #
  get 'search' => "search#show"
  get 'search/autocomplete' => "search#autocomplete", as: :search_autocomplete

  # API
  API::API.logger Rails.logger
  mount API::API => '/api'

  # Get all keys of user
  get ':username.keys' => 'profiles/keys#get_keys' , constraints: { username: /.*/ }

  constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.admin? }

  constraints constraint do
    mount Resque::Server.new, at: '/resque_web', as: :resque_web
  end

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git.bin_path,
    project_root: Gitlab.config.gitlab_shell.repos_path,
    upload_pack:  Gitlab.config.gitlab_shell.upload_pack,
    receive_pack: Gitlab.config.gitlab_shell.receive_pack
  }), at: '/', constraints: lambda { |request| /[-\/\w\.]+\.git\//.match(request.path_info) }, via: [:get, :post]

  #
  # Help
  #

  get 'help'                  => 'help#index'
  get 'help/:category/:file'  => 'help#show', as: :help_page
  get 'help/shortcuts'

  #
  # Global snippets
  #
  resources :snippets do
    member do
      get "raw"
    end
  end

  get "/s/:username" => "snippets#user_index", as: :user_snippets, constraints: { username: /.*/ }

  #
  # Public namespace
  #
  namespace :public do
    resources :projects, only: [:index]
    root to: "projects#index"
  end

  resources :events, only: [:index]

  #
  # Attachments serving
  #
  get 'files/:type/:id/:filename' => 'files#download', constraints: { id: /\d+/, type: /[a-z]+/, filename:  /.+/ }

  #
  # Admin Area
  #
  namespace :admin do
    resources :users, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ } do
      member do
        put :team_update
        put :block
        put :unblock
      end
    end

    resources :groups, constraints: { id: /[^\/]+/ } do
      member do
        put :project_teams_update
      end
    end

    resources :teams

    resources :services do
      scope module: :services do
        resources :keys do
          member do
            put :enable
            put :disable
          end
        end
      end
    end

    resources :hooks, only: [:index, :create, :destroy] do
      get :test
    end

    resources :broadcast_messages, only: [:index, :create, :destroy]
    resource :logs, only: [:show]
    resource :background_jobs, controller: 'background_jobs', only: [:show]
    resources :projects, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }, only: [:index, :show, :destroy] do
      member do
        put :transfer
      end
    end

    resource :settings, only: [:show, :edit, :update] do
      scope module: :settings do
        resources :email_domains
      end
    end

    root to: "dashboard#index"
  end

  namespace :notifications do
    resource :subscription, only: [:create] do
      collection do
        post :mass_create
        post :to_all
        delete :from_all
      end
    end
  end

  #
  # Profile Area
  #
  resource :profile, only: [:show, :update] do
    member do
      get :history
      get :design

      put :reset_private_token
      put :update_username

    end

    scope module: :profiles do
      resources :subscriptions
      resources :favourites, only: [:index]
      resources :summaries do
        member do
          get :send_now
        end
        scope module: :summaries do
          resources :projects, only: [:create, :update, :destroy]
          resources :groups, only: [:create, :update, :destroy]
          resources :teams, only: [:create, :update, :destroy]
          resources :users, only: [:create, :update, :destroy]
        end
      end
      resources :tokens,  only: [:index, :destroy]
      resources :auto_subscriptions, only: [:create, :destroy]
      resource :notification_settings, only: [:update]
    end

    scope module: :profiles do
      resource :account, only: [:show, :update]
      resource :notifications, only: [:show, :update]
      resource :password, only: [:new, :create, :edit, :update] do
        member do
          put :reset
        end
      end
      resources :keys
      resources :emails, only: [:index, :create, :destroy]
      resources :groups, only: [:index] do
        member do
          delete :leave
        end
      end
      resource :avatar, only: [:destroy]
    end
  end

  match "/u/:username" => "users#show", as: :user, constraints: { username: /.*/ }, via: :get

  #
  # Dashboard Area
  #
  resource :dashboard, controller: "dashboard", only: [:show] do
    member do
      get :projects
      get :groups
      get :teams
      get :issues
      get :merge_requests
    end
  end

  #
  # Teams Area
  #
  resources :teams do
    scope module: :teams do
      resources :members,   only: [:index, :create, :update, :destroy]
      resources :projects,  only: [:index, :create, :destroy], constraints: { id: /[a-zA-Z.0-9_\-]+\/[a-zA-Z.0-9_\-]+/ }
      resources :groups,    only: [:index, :create, :destroy]
    end
  end

  #
  # Groups Area
  #
  resources :groups, constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}  do
    member do
      get :issues
      get :merge_requests
    end

    scope module: :groups do
      resources :teams, only: [:index, :create, :destroy]
      resources :members, only: [:index, :create, :update, :destroy]
      resources :projects, only: [:index]
    end

    resources :users_groups, only: [:create, :update, :destroy]
    scope module: :groups do
      resource :avatar, only: [:destroy]
    end
  end

  resources :projects, constraints: { id: /[^\/]+/ }, only: [:new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks, registrations: :registrations , passwords: :passwords}

  #
  # Project Area
  #
  resources :projects, constraints: { id: /[a-zA-Z.0-9_\-]+\/[a-zA-Z.0-9_\-]+/ }, except: [:new, :create, :index], path: "/" do
    member do
      put :transfer
      post :fork
      post :archive
      post :unarchive
      post :upload_image
      get :autocomplete_sources
      get :import
      put :retry_import
    end

    scope module: :projects do
      resources :blob,      only: [:show, :destroy], constraints: {id: /.+/} do
        get :diff, on: :member
      end
      resources :raw,       only: [:show], constraints: {id: /.+/}
      resources :tree,      only: [:show], constraints: {id: /.+/, format: /(html|js)/ }
      resources :edit_tree, only: [:show, :update], constraints: { id: /.+/ }, path: 'edit' do
        post :preview, on: :member
      end
      resources :new_tree,  only: [:show, :update], constraints: {id: /.+/}, path: 'new'
      resources :commit,    only: [:show], constraints: {id: /[[:alnum:]]{6,40}/}
      resources :commits,   only: [:show], constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}
      resources :compare,   only: [:index, :create]
      resources :blame,     only: [:show], constraints: {id: /.+/}
      resources :network,   only: [:show], constraints: {id: /(?:[^.]|\.(?!json$))+/, format: /json/}
      resources :graphs,    only: [:show], constraints: {id: /(?:[^.]|\.(?!json$))+/, format: /json/}
      resources :ci_builds, only: [:show], constraints: {id: /.+/} do
        member do
          post :rebuild
        end
      end

      match "/compare/:from...:to" => "compare#show", as: "compare", via: [:get, :post], constraints: {from: /.+/, to: /.+/}

      resources :snippets, constraints: {id: /\d+/} do
        member do
          get "raw"
        end
      end

      resources :wikis, only: [:show, :edit, :destroy, :create], constraints: {id: /[a-zA-Z.0-9_\-\/]+/} do
        collection do
          get :pages
          put ':id' => 'wikis#update'
          get :git_access
        end

        member do
          get "history"
        end
      end

      resource :repository, only: [:show] do
        member do
          get "stats"
          get "archive", constraints: { format: Gitlab::Regex.archive_formats_regex }
        end
      end

      resources :services, constraints: { id: /[^\/]+/ }, only: [:index, :edit, :update] do
        member do
          get :test
        end
      end

      resources :deploy_keys, constraints: {id: /\d+/} do
        member do
          put :enable
          put :disable
        end
      end

      resources :branches, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
      resources :tags, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
      resources :protected_branches, only: [:index, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }

      resources :refs, only: [] do
        collection do
          get "switch"
        end

        member do
          # tree viewer logs
          get "logs_tree", constraints: { id: Gitlab::Regex.git_reference_regex }
          get "logs_tree/:path" => "refs#logs_tree",
            as: :logs_file,
            constraints: {
              id:   Gitlab::Regex.git_reference_regex,
              path: /.*/
            }
        end
      end

      resources :merge_requests, constraints: {id: /\d+/}, except: [:destroy] do
        member do
          get :diffs
          post :automerge
          get :automerge_check
          get :ci_status
        end

        collection do
          get :branch_from
          get :branch_to
          get :update_branches
        end
      end

      resources :hooks, only: [:index, :create, :destroy], constraints: {id: /\d+/} do
        member do
          get :test
        end
      end

      resources :team, controller: 'team_members', only: [:index]
      resources :teams, only: [:index, :create, :destroy], constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ }
      resources :milestones, except: [:destroy], constraints: {id: /\d+/} do
        member do
          put :sort_issues
          put :sort_merge_requests
        end
      end

      resources :labels, only: [:index] do
        collection do
          post :generate
        end
      end

      resources :issues, constraints: {id: /\d+/}, except: [:destroy] do
        collection do
          post  :bulk_update
        end
      end

      resources :team_members, except: [:index, :edit], constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ } do
        collection do
          delete :leave

          post :batch_update
          delete :batch_delete

          # Used for import team
          # from another project
          get :import
          post :apply_import
        end
      end

      resources :notes, only: [:index, :create, :destroy, :update], constraints: {id: /\d+/} do
        member do
          delete :delete_attachment
        end
        collection do
          post :preview
        end
      end

      resources :tokens,  only: [:index, :show, :create, :destroy], constraints: {id: /\d+/}
    end
  end

  get ':id' => "namespaces#show", constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}

  root to: "dashboard#show"
end
