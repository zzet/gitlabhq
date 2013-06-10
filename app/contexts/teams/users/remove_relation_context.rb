module Teams
  module Users
    class RemoveRelationContext < Teams::Users::BaseContext

      def initialize(actor, team, user)
        @current_user, @team, @user = actor, team, user
      end

      def execute
        @team.remove_member(@user)

        receive_delayed_notifications
      end
    end
  end
end
