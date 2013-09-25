module Groups
  module Users
    class CreateRelationContext < Groups::BaseContext
      def execute
        user_ids = params[:user_ids].respond_to?(:each) ? params[:user_ids] : params[:user_ids].split(',')
        @group.add_users(user_ids, params[:group_access])

        receive_delayed_notifications
      end
    end
  end
end
