module Projects
  module Teams
    class CreateRelationContext < Projects::BaseContext
      def execute
        unless params[:team_ids].blank?
          team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')
          team_ids.each do |team_id|
            team = Team.find(team_id)
            params[:project_ids] = [project.id]
            ::Teams::Projects::CreateRelationContext.new(current_user, team, params).execute
          end
        end
      end
    end
  end
end
