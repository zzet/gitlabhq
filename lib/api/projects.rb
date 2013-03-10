module Gitlab
  # Projects API
  class Projects < Grape::API
    before { authenticate! }

    resource :projects do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end
          not_found!
        end
      end

      # Get a projects list for authenticated user
      #
      # Example Request:
      #   GET /projects
      get do
        @projects = paginate current_user.authorized_projects
        present @projects, with: Entities::Project
      end

      # Get a single project
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id
      get ":id" do
        present user_project, with: Entities::Project
      end

      # Create new project
      #
      # Parameters:
      #   name (required) - name for new project
      #   description (optional) - short project description
      #   default_branch (optional) - 'master' by default
      #   issues_enabled (optional) - enabled by default
      #   wall_enabled (optional) - enabled by default
      #   merge_requests_enabled (optional) - enabled by default
      #   wiki_enabled (optional) - enabled by default
      #   namespace_id (optional) - defaults to user namespace
      # Example Request
      #   POST /projects
      post do
        required_attributes! [:name]
        attrs = attributes_for_keys [:name,
                                    :description,
                                    :default_branch,
                                    :issues_enabled,
                                    :wall_enabled,
                                    :merge_requests_enabled,
                                    :wiki_enabled,
                                    :namespace_id]
        @project = ::Projects::CreateContext.new(current_user, attrs).execute
        if @project.saved?
          present @project, with: Entities::Project
        else
          if @project.errors[:limit_reached].present?
            error!(@project.errors[:limit_reached], 403)
          end
          not_found!
        end
      end

      # Create new project for a specified user.  Only available to admin users.
      #
      # Parameters:
      #   user_id (required) - The ID of a user
      #   name (required) - name for new project
      #   description (optional) - short project description
      #   default_branch (optional) - 'master' by default
      #   issues_enabled (optional) - enabled by default
      #   wall_enabled (optional) - enabled by default
      #   merge_requests_enabled (optional) - enabled by default
      #   wiki_enabled (optional) - enabled by default
      # Example Request
      #   POST /projects/user/:user_id
      post "user/:user_id" do
        authenticated_as_admin!
        user = User.find(params[:user_id])
        attrs = attributes_for_keys [:name,
                                    :description,
                                    :default_branch,
                                    :issues_enabled,
                                    :wall_enabled,
                                    :merge_requests_enabled,
                                    :wiki_enabled]
        @project = ::Projects::CreateContext.new(user, attrs).execute
        if @project.saved?
          present @project, with: Entities::Project
        else
          not_found!
        end
      end


      # Get a project team members
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   query         - Query string
      # Example Request:
      #   GET /projects/:id/members
      get ":id/members" do
        if params[:query].present?
          @members = paginate user_project.users.where("username LIKE ?", "%#{params[:query]}%")
        else
          @members = paginate user_project.users
        end
        present @members, with: Entities::ProjectMember, project: user_project
      end

      # Get a project team members
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a user
      # Example Request:
      #   GET /projects/:id/members/:user_id
      get ":id/members/:user_id" do
        @member = user_project.users.find params[:user_id]
        present @member, with: Entities::ProjectMember, project: user_project
      end

      # Add a new project team member
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a user
      #   access_level (required) - Project access level
      # Example Request:
      #   POST /projects/:id/members
      post ":id/members" do
        authorize! :admin_project, user_project
        required_attributes! [:user_id, :access_level]

        # either the user is already a team member or a new one
        team_member = user_project.team_member_by_id(params[:user_id])
        if team_member.nil?
          team_member = user_project.users_projects.new(
            user_id: params[:user_id],
            project_access: params[:access_level]
          )
        end

        if team_member.save
          @member = team_member.user
          present @member, with: Entities::ProjectMember, project: user_project
        else
          handle_project_member_errors team_member.errors
        end
      end

      # Update project team member
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a team member
      #   access_level (required) - Project access level
      # Example Request:
      #   PUT /projects/:id/members/:user_id
      put ":id/members/:user_id" do
        authorize! :admin_project, user_project
        required_attributes! [:access_level]

        team_member = user_project.users_projects.find_by_user_id(params[:user_id])
        not_found!("User can not be found") if team_member.nil?

        if team_member.update_attributes(project_access: params[:access_level])
          @member = team_member.user
          present @member, with: Entities::ProjectMember, project: user_project
        else
          handle_project_member_errors team_member.errors
        end
      end

      # Remove a team member from project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a team member
      # Example Request:
      #   DELETE /projects/:id/members/:user_id
      delete ":id/members/:user_id" do
        authorize! :admin_project, user_project
        team_member = user_project.users_projects.find_by_user_id(params[:user_id])
        unless team_member.nil?
          team_member.destroy
        else
          {:message => "Access revoked", :id => params[:user_id].to_i}
        end
      end

      # Get project hooks
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/hooks
      get ":id/hooks" do
        authorize! :admin_project, user_project
        @hooks = paginate user_project.hooks
        present @hooks, with: Entities::Hook
      end

      # Get a project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      # Example Request:
      #   GET /projects/:id/hooks/:hook_id
      get ":id/hooks/:hook_id" do
        authorize! :admin_project, user_project
        @hook = user_project.hooks.find(params[:hook_id])
        present @hook, with: Entities::Hook
      end


      # Add hook to project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   url (required) - The hook URL
      # Example Request:
      #   POST /projects/:id/hooks
      post ":id/hooks" do
        authorize! :admin_project, user_project
        required_attributes! [:url]

        @hook = user_project.hooks.new({"url" => params[:url]})
        if @hook.save
          present @hook, with: Entities::Hook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!
        end
      end

      # Update an existing project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      #   url (required) - The hook URL
      # Example Request:
      #   PUT /projects/:id/hooks/:hook_id
      put ":id/hooks/:hook_id" do
        @hook = user_project.hooks.find(params[:hook_id])
        authorize! :admin_project, user_project
        required_attributes! [:url]

        attrs = attributes_for_keys [:url]
        if @hook.update_attributes attrs
          present @hook, with: Entities::Hook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!
        end
      end

      # Deletes project hook. This is an idempotent function.
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of hook to delete
      # Example Request:
      #   DELETE /projects/:id/hooks/:hook_id
      delete ":id/hooks" do
        authorize! :admin_project, user_project
        required_attributes! [:hook_id]

        begin
          @hook = ProjectHook.find(params[:hook_id])
          @hook.destroy
        rescue
          # ProjectHook can raise Error if hook_id not found
        end
      end

      # Get a project repository branches
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        present user_project.repo.heads.sort_by(&:name), with: Entities::RepoObject, project: user_project
      end

      # Get a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   GET /projects/:id/repository/branches/:branch
      get ":id/repository/branches/:branch" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found!("Branch does not exist") if @branch.nil?
        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Protect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/protect
      put ":id/repository/branches/:branch/protect" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found! unless @branch
        protected = user_project.protected_branches.find_by_name(@branch.name)

        unless protected
          user_project.protected_branches.create(:name => @branch.name)
        end

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Unprotect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/unprotect
      put ":id/repository/branches/:branch/unprotect" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found! unless @branch
        protected = user_project.protected_branches.find_by_name(@branch.name)

        if protected
          protected.destroy
        end

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Get a project repository tags
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/tags
      get ":id/repository/tags" do
        present user_project.repo.tags.sort_by(&:name).reverse, with: Entities::RepoObject
      end

      # Get a project repository commits
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   ref_name (optional) - The name of a repository branch or tag, if not given the default branch is used
      # Example Request:
      #   GET /projects/:id/repository/commits
      get ":id/repository/commits" do
        authorize! :download_code, user_project

        page = params[:page] || 0
        per_page = (params[:per_page] || 20).to_i
        ref = params[:ref_name] || user_project.try(:default_branch) || 'master'

        commits = user_project.repository.commits(ref, nil, per_page, page * per_page)
        present CommitDecorator.decorate(commits), with: Entities::RepoCommit
      end

      # Get a project snippets
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/snippets
      get ":id/snippets" do
        present paginate(user_project.snippets), with: Entities::ProjectSnippet
      end

      # Get a project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   GET /projects/:id/snippets/:snippet_id
      get ":id/snippets/:snippet_id" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        present @snippet, with: Entities::ProjectSnippet
      end

      # Create a new project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   title (required) - The title of a snippet
      #   file_name (required) - The name of a snippet file
      #   lifetime (optional) - The expiration date of a snippet
      #   code (required) - The content of a snippet
      # Example Request:
      #   POST /projects/:id/snippets
      post ":id/snippets" do
        authorize! :write_snippet, user_project
        required_attributes! [:title, :file_name, :code]

        attrs = attributes_for_keys [:title, :file_name]
        attrs[:expires_at] = params[:lifetime] if params[:lifetime].present?
        attrs[:content] = params[:code] if params[:code].present?
        @snippet = user_project.snippets.new attrs
        @snippet.author = current_user

        if @snippet.save
          present @snippet, with: Entities::ProjectSnippet
        else
          not_found!
        end
      end

      # Update an existing project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      #   title (optional) - The title of a snippet
      #   file_name (optional) - The name of a snippet file
      #   lifetime (optional) - The expiration date of a snippet
      #   code (optional) - The content of a snippet
      # Example Request:
      #   PUT /projects/:id/snippets/:snippet_id
      put ":id/snippets/:snippet_id" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        authorize! :modify_snippet, @snippet

        attrs = attributes_for_keys [:title, :file_name]
        attrs[:expires_at] = params[:lifetime] if params[:lifetime].present?
        attrs[:content] = params[:code] if params[:code].present?

        if @snippet.update_attributes attrs
          present @snippet, with: Entities::ProjectSnippet
        else
          not_found!
        end
      end

      # Delete a project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   DELETE /projects/:id/snippets/:snippet_id
      delete ":id/snippets/:snippet_id" do
        begin
          @snippet = user_project.snippets.find(params[:snippet_id])
          authorize! :modify_snippet, user_project
          @snippet.destroy
        rescue
        end
      end

      # Get a raw project snippet
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   snippet_id (required) - The ID of a project snippet
      # Example Request:
      #   GET /projects/:id/snippets/:snippet_id/raw
      get ":id/snippets/:snippet_id/raw" do
        @snippet = user_project.snippets.find(params[:snippet_id])
        content_type 'text/plain'
        present @snippet.content
      end

      # Get a raw file contents
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit or branch name
      #   filepath (required) - The path to the file to display
      # Example Request:
      #   GET /projects/:id/repository/commits/:sha/blob
      get ":id/repository/commits/:sha/blob" do
        authorize! :download_code, user_project
        required_attributes! [:filepath]

        ref = params[:sha]

        commit = user_project.repository.commit ref
        not_found! "Commit" unless commit

        tree = Tree.new commit.tree, ref, params[:filepath]
        not_found! "File" unless tree.try(:tree)

        content_type tree.mime_type
        present tree.data
      end

      # Get a specific project's keys
      #
      # Example Request:
      #   GET /projects/:id/keys
      get ":id/keys" do
        present user_project.deploy_keys, with: Entities::SSHKey
      end

      # Get single key owned by currently authenticated user
      #
      # Example Request:
      #   GET /projects/:id/keys/:id
      get ":id/keys/:key_id" do
        key = user_project.deploy_keys.find params[:key_id]
        present key, with: Entities::SSHKey
      end

      # Add new ssh key to currently authenticated user
      #
      # Parameters:
      #   key (required) - New SSH Key
      #   title (required) - New SSH Key's title
      # Example Request:
      #   POST /projects/:id/keys
      post ":id/keys" do
        attrs = attributes_for_keys [:title, :key]
        key = user_project.deploy_keys.new attrs
        if key.save
          present key, with: Entities::SSHKey
        else
          not_found!
        end
      end

      # Delete existed ssh key of currently authenticated user
      #
      # Example Request:
      #   DELETE /projects/:id/keys/:id
      delete ":id/keys/:key_id" do
        key = user_project.deploy_keys.find params[:key_id]
        key.delete
      end

    end
  end
end
