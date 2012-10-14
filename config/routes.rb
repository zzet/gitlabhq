Gitlab::Application.routes.draw do

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks }

  # API
  require 'api'
  mount Gitlab::API => '/api'

  # Optionally, enable Resque here
  require 'resque/server'
  mount Resque::Server => '/info/resque', as: 'resque'

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git_bin_path,
    project_root: Gitlab.config.git_base_path,
    upload_pack:  Gitlab.config.git_upload_pack,
    receive_pack: Gitlab.config.git_receive_pack
  }), at: '/:path', constraints: { path: /[\w-]+\.git/ }

  scope :module => :web do
    #
    # Search
    #
    resource :search, :only => [:show]

    #
    # Help
    #
    resource :help, :only => [] do
      collection do
        get :index
        get :permissions
        get :workflow
        get :api
        get :web_hooks
        get :system_hooks
        get :markdown
        get :ssh
      end
    end

    #
    # Admin Area
    #
    namespace :admin do
      resources :users do
        member do
          put :team_update
          put :block
          put :unblock
        end
      end
      resources :groups, constraints: { id: /[^\/]+/ } do
        member do
          put :project_update
          delete :remove_project
        end
      end
      resources :projects, constraints: { id: /[^\/]+/ } do
        member do
          get :team
          put :team_update
        end
      end
      resources :team_members, only: [:edit, :update, :destroy]
      resources :hooks, only: [:index, :create, :destroy] do
        get :test
      end
      resource :logs, only: [:show]
      resource :resque, controller: 'resque', only: [:show]
      root to: "dashboard#index"
    end

    resources :errors, :only => [] do
      collection do
        get :githost
      end
    end

    #
    # Profile Area
    #
    resource :profile, :only => [:show, :update] do
      collection do
        get :account
        get :history
        put :password, action: :password_update
        get :token
        put :reset_private_token
        get :design
      end

      scope :module => :profiles do
        resources :keys
      end
    end

    #
    # Dashboard Area
    #
    resources :dashboard, :only => [:index] do
      collection do
        get :issues
        get :merge_requests
      end
    end


    #
    # Groups Area
    #
    resources :groups, constraints: { id: /[^\/]+/ }, only: [:show] do
      member do
        get :issues
        get :merge_requests
        get :search
        get :people
      end
    end

    resources :projects, constraints: { id: /[^\/]+/ }, only: [:new, :create]


    #
    # Project Area
    #
    resources :projects, constraints: { id: /[^\/]+/ }, except: [:new, :create, :index], path: "/" do
      member do
        get "wall"
        get "graph"
        get "files"
      end

      scope :module => :projects do

        resources :wikis, only: [:show, :edit, :destroy, :create] do
          collection do
            get :pages
          end

          member do
            get "history"
          end
        end

        resource :repository do
          member do
            get "branches"
            get "tags"
            get "archive"
          end
        end

        resources :deploy_keys
        resources :protected_branches, only: [:index, :create, :destroy]

        resources :refs, only: [], path: "/" do
          collection do
            get "switch"
          end

          member do
            # tree viewer logs
            get "logs_tree", constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }
            get "logs_tree/:path" => "refs#logs_tree",
              as: :logs_file,
              constraints: {
              id:   /[a-zA-Z.0-9\/_\-]+/,
              path: /.*/
            }
          end
        end

        resources :merge_requests do
          member do
            get :diffs
            get :automerge
            get :automerge_check
            get :raw
          end

          collection do
            get :branch_from
            get :branch_to
          end
        end

        resources :snippets do
          member do
            get "raw"
          end
        end

        resources :hooks, only: [:index, :create, :destroy] do
          member do
            get :test
          end
        end

        resources :commit,  only: [:show], constraints: {id: /[[:alnum:]]{6,40}/}, :controller => :commits
        resources :commits, only: [:index,:show]
        resources :compare, only: [:index, :create]
        resources :blame,   only: [:show], constraints: {id: /.+/}
        resources :blob,    only: [:show], constraints: {id: /.+/}
        resources :tree,    only: [:show], constraints: {id: /.+/}
        match "/compare/:from...:to" => "compare#show", as: "compare",
          :via => [:get, :post], constraints: {from: /.+/, to: /.+/}

        resources :team, controller: 'team_members', only: [:index]
        resources :team_members
        resources :milestones
        resources :labels, only: [:index]
        resources :issues do
          collection do
            post  :sort
            post  :bulk_update
            get   :search
          end
        end

        resources :notes, only: [:index, :create, :destroy] do
          collection do
            post :preview
          end
        end
      end

    end
    root to: "dashboard#index"
  end
end
