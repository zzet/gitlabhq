module Teams
  module Groups
    class UpdateRelationContext < Teams::Groups::BaseContext
      def execute
        permission = params[:greatest_project_access]
        rebuild_flag = params[:rebuild_permissions]

        Gitlab::UserTeamManager.update_team_user_access_in_group(team, group, permission, rebuild_flag)

        receive_delayed_notifications
      end
    end
  end
end
