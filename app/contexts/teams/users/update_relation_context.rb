module Teams
  module Users
    class UpdateRelationContext < Teams::Users::BaseContext
      def execute
        result = @team.team_user_relationships.find_by_user_id(@user).update_attributes(team_access: params[:team_access])

        receive_delayed_notifications

        result
      end
    end
  end
end
