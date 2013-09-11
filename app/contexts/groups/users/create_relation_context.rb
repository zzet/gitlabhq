module Groups
  module Users
    class CreateRelationContext < Groups::BaseContext
      def execute
        @group.add_users(params[:user_ids].split(','), params[:group_access])

        receive_delayed_notifications
      end
    end
  end
end
