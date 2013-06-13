module Teams
  module Projects
    class CreateRelationContext < Teams::BaseContext
      def execute
        project_ids = params[:project_ids]
        access = params[:greatest_project_access]

        # Reject non-allowed projects
        allowed_project_ids = current_user.owned_projects.map(&:id)
        project_ids.select! { |id| allowed_project_ids.include?(id.to_i) }

        # Assign projects to team
        project_ids.each do |project|
          Gitlab::UserTeamManager.assign(team, project, access)
        end

        receive_delayed_notifications
      end
    end
  end
end
