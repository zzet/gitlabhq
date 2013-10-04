module Groups
  module Teams
    class RemoveRelationContext < Groups::Teams::BaseContext
      def execute
        group_team_relation.destroy
        receive_delayed_notifications
      end
    end
  end
end
