module Projects
  module Users
    class RemoveRelationContext < Projects::Users::BaseContext
      def execute
        team_member_relation.destroy

        receive_delayed_notifications
      end
    end
  end
end
