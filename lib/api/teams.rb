module API
  # teams API
  class Teams < Grape::API
    before { authenticate! }

    resource :teams do
      helpers do
        def find_team(id)
          team = Team.find(id)

          if can?(current_user, :read_team, team)
            team
          else
            render_api_error!("403 Forbidden - #{current_user.username} lacks sufficient access to #{team.name}", 403)
          end
        end

        def validate_access_level?(level)
          Gitlab::Access.options_with_owner.values.include? level.to_i
        end
      end

      # Get a teams list
      #
      # Example Request:
      #  GET /teams
      get do
        search_options = { page: params[:page] }
        search_options[:tids] = current_user.known_teams.pluck(:id) unless current_user.admin?
        @teams = Team.search(params[:search], options: search_options)
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

      # Get a single team, with containing projects
      #
      # Parameters:
      #   id (required) - The ID of a team
      # Example Request:
      #   GET /teams/:id
      get ":id" do
        team = find_team(params[:id])
        present team, with: Entities::TeamDetail
      end

      # Remove team
      #
      # Parameters:
      #   id (required) - The ID of a team
      # Example Request:
      #   DELETE /teams/:id
      delete ":id" do
        team = find_team(params[:id])
        authorize! :manage_team, team
        team.destroy
      end

      # Get a list of team members viewable by the authenticated user.
      #
      # Example Request:
      #  GET /teams/:id/members
      get ":id/members" do
        team = find_team(params[:id])
        members = team.users_teams
        users = (paginate members).collect(&:user)
        present users, with: Entities::TeamMember, team: team
      end
    end
  end
end
