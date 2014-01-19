module API
  # teams API
  class Teams < Grape::API
    before { authenticate! }

    resource :teams do
      helpers do
        def handle_team_member_errors(errors)
          if errors[:permission].any?
            render_api_error!(errors[:permission], 422)
          end
          not_found!
        end

        def validate_access_level?(level)
          [UsersProject::GUEST, UsersProject::REPORTER, UsersProject::DEVELOPER, UsersProject::MASTER].include? level.to_i
        end
      end


      # Get a teams list
      #
      # Example Request:
      #  GET /teams
      get do
        if current_user.admin
          @teams = paginate Team
        else
          @teams = paginate current_user.teams
        end
        present @teams, with: Entities::Team
      end


      # Create team. Available only for admin
      #
      # Parameters:
      #   name (required) - The name of the team
      #   path (required) - The path of the team
      # Example Request:
      #   POST /teams
      post do
        authenticated_as_admin!
        required_attributes! [:name, :path]

        attrs = attributes_for_keys [:name, :path]
        @team = Team.new(attrs)
        @team.owner = current_user

        if @team.save
          present @team, with: Entities::Team
        else
          not_found!
        end
      end


      # Get a single team
      #
      # Parameters:
      #   id (required) - The ID of a team
      # Example Request:
      #   GET /teams/:id
      get ":id" do
        @team = Team.find(params[:id])
        if current_user.admin or current_user.teams.include? @team
          present @team, with: Entities::Team
        else
          not_found!
        end
      end


      # Get team members
      #
      # Parameters:
      #   id (required) - The ID of a team
      # Example Request:
      #   GET /teams/:id/members
      get ":id/members" do
        @team = Team.find(params[:id])
        if current_user.admin or current_user.teams.include? @team
          @members = paginate @team.members
          present @members, with: Entities::TeamMember, team: @team
        else
          not_found!
        end
      end


      # Add a new team member
      #
      # Parameters:
      #   id (required) - The ID of a team
      #   user_id (required) - The ID of a user
      #   access_level (required) - Project access level
      # Example Request:
      #   POST /teams/:id/members
      post ":id/members" do
        authenticated_as_admin!
        required_attributes! [:user_id, :access_level]

        if not validate_access_level?(params[:access_level])
          render_api_error!("Wrong access level", 422)
        end

        @team = Team.find(params[:id])
        if @team
          team_member = @team.team_user_relationships.find_by_user_id(params[:user_id])
          # Not existing member
          if team_member.nil?
            @team.add_member(params[:user_id], params[:access_level], false)
            team_member = @team.team_user_relationships.find_by_user_id(params[:user_id])

            if team_member.nil?
              render_api_error!("Error creating membership", 500)
            else
              @member = team_member.user
              present @member, with: Entities::TeamMember, team: @team
            end
          else
            render_api_error!("Already exists", 409)
          end
        else
          not_found!
        end
      end


      # Get a single team member from team
      #
      # Parameters:
      #   id (required) - The ID of a team
      #   user_id (required) - The ID of a team member
      # Example Request:
      #   GET /teams/:id/members/:user_id
      get ":id/members/:user_id" do
        @team = Team.find(params[:id])
        if current_user.admin or current_user.teams.include? @team
          team_member = @team.team_user_relationships.find_by_user_id(params[:user_id])
          unless team_member.nil?
            present team_member.user, with: Entities::TeamMember, team: @team
          else
            not_found!
          end
        else
          not_found!
        end
      end

      # Remove a team member from team
      #
      # Parameters:
      #   id (required) - The ID of a team
      #   user_id (required) - The ID of a team member
      # Example Request:
      #   DELETE /teams/:id/members/:user_id
      delete ":id/members/:user_id" do
        authenticated_as_admin!

        @team = Team.find(params[:id])
        if @team
          team_member = @team.team_user_relationships.find_by_user_id(params[:user_id])
          unless team_member.nil?
            Teams::Users::RemoveRelationService.new(current_user, @team, team_member).execute
          else
            not_found!
          end
        else
          not_found!
        end
      end


      # Get to team assigned projects
      #
      # Parameters:
      #   id (required) - The ID of a team
      # Example Request:
      #   GET /teams/:id/projects
      get ":id/projects" do
        @team = Team.find(params[:id])
        if current_user.admin or current_user.teams.include? @team
          @projects = paginate @team.projects
          present @projects, with: Entities::TeamProject, team: @team
        else
          not_found!
        end
      end


      # Add a new team project
      #
      # Parameters:
      #   id (required) - The ID of a team
      #   project_id (required) - The ID of a project
      #   greatest_access_level (required) - Project access level
      # Example Request:
      #   POST /teams/:id/projects
      post ":id/projects" do
        authenticated_as_admin!
        required_attributes! [:project_id, :greatest_access_level]

        if not validate_access_level?(params[:greatest_access_level])
          render_api_error!("Wrong greatest_access_level", 422)
        end

        @team = Team.find(params[:id])
        if @team
          team_project = @team.team_project_relationships.find_by_project_id(params[:project_id])

          # No existing project
          if team_project.nil?
            @team.assign_to_projects([params[:project_id]], params[:greatest_access_level])
            team_project = @team.team_project_relationships.find_by_project_id(params[:project_id])
            if team_project.nil?
              render_api_error!("Error creating project assignment", 500)
            else
              @project = team_project.project
              present @project, with: Entities::TeamProject, team: @team
            end
          else
            render_api_error!("Already exists", 409)
          end
        else
          not_found!
        end
      end

      # Show a single team project from team
      #
      # Parameters:
      #   id (required) - The ID of a team
      #   project_id (required) - The ID of a project assigned to the team
      # Example Request:
      #   GET /teams/:id/projects/:project_id
      get ":id/projects/:project_id" do
        @team = Team.find(params[:id])
        if current_user.admin or current_user.teams.include? @team
          team_project = @team.team_project_relationships.find_by_project_id(params[:project_id])
          unless team_project.nil?
            present team_project.project, with: Entities::TeamProject, team: @team
          else
            not_found!
          end
        else
          not_found!
        end
      end

      # Remove a team project from team
      #
      # Parameters:
      #   id (required) - The ID of a team
      #   project_id (required) - The ID of a project assigned to the team
      # Example Request:
      #   DELETE /teams/:id/projects/:project_id
      delete ":id/projects/:project_id" do
        authenticated_as_admin!

        @team = Team.find(params[:id])
        if @team
          team_project = @team.team_project_relationships.find_by_project_id(params[:project_id])
          unless team_project.nil?
            team_project.destroy
          else
            not_found!
          end
        else
          not_found!
        end
      end

    end
  end
end
