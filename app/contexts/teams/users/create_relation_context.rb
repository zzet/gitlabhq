module Teams
  module Users
    class CreateRelationContext < Teams::BaseContext
      def execute
        unless params[:user_ids].blank?
          user_ids = params[:user_ids].respond_to?(:each) ? params[:user_ids] : params[:user_ids].split(',')
          access = params[:permission]
          is_admin = params[:group_admin]
          @team.add_members(user_ids, access, is_admin)
        end

        receive_delayed_notifications
      end
    end
  end
end
