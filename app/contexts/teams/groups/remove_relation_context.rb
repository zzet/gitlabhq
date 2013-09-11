module Teams
  module Groups
    class RemoveRelationContext < Teams::Groups::BaseContext
      def execute
        team.team_group_relationship.find_by_group_id(group).destroy_all

        receive_delayed_notifications
      end
    end
  end
end
