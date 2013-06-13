module Teams
  module Groups
    class RemoveRelationContext < Teams::Groups::BaseContext
      def execute
        Gitlab::UserTeamManager.resign_from_group(team, group)

        receive_delayed_notifications
      end
    end
  end
end
