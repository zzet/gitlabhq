module Projects
  module Teams
    class CreateRelationContext < Projects::BaseContext
      def execute
        unless params[:team_id].blank?
          team = Team.find(params[:team_id])
          params[:project_ids] = [project.id]
          ::Teams::Projects::CreateRelationContext.new(current_user, team, params).execute
        end
      end
    end
  end
end
