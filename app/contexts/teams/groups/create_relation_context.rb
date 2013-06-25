module Teams
  module Groups
    class CreateRelationContext < Teams::Groups::BaseContext
      def execute
        permission = params[:greatest_project_access]
        Gitlab::UserTeamManager.assign_to_group(team, group, permission)

        receive_delayed_notifications
      end
    end
  end
end
