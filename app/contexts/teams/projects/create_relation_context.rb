module Teams
  module Projects
    class CreateRelationContext < Teams::BaseContext
      def execute
        project_ids = params[:project_ids].respond_to?(:each) ? params[:project_ids] : params[:project_ids].split(',')

        unless current_user.admin?
          allowed_project_ids = (current_user.master_projects.pluck(:id) + current_user.own_projects.pluck(:id) + current_user.owned_projects.pluck(:id)).uniq
          project_ids.select! { |id| allowed_project_ids.include?(id.to_i) }
        end

        project_ids.each do |project|
          team.team_project_relationships.create(project_id: project)
        end

        receive_delayed_notifications
      end
    end
  end
end
