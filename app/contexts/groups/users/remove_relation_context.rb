module Groups
  module Users
    class RemoveRelationContext < Groups::Users::BaseContext
      def execute
        if group_member_relation.user != group.owner
          group_member_relation.destroy

          receive_delayed_notifications
        end
      end
    end
  end
end
