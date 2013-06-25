module Teams
  module Users
    class RemoveRelationContext < Teams::Users::BaseContext
      def execute
        @team.remove_member(@user)

        receive_delayed_notifications
      end
    end
  end
end
