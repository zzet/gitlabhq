module Projects
  module Teams
    class CreateRelationContext < Projects::BaseContext
      def execute
        params.symbolize_keys!
        unless params[:team_id].blank?
          team = UserTeam.find(params[:team_id])
          params[:project_ids] = [project.id]
          ::Teams::Projects::CreateRelationContext.new(current_user, team, params).execute
        end
      end
    end
  end
end
