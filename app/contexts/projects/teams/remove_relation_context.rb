module Projects
  module Teams
    class RemoveRelationContext < Projects::BaseContext
      def execute
        team = project.user_teams.find_by_path(params[:id])

        Teams::Projects::RemoveRelationContext.new(@current_user, team, project).execute
      end
    end
  end
end
