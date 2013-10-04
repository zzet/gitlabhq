module Teams
  module Users
    class CreateRelationContext < Teams::BaseContext
      def execute
        unless params[:user_ids].blank?
          user_ids = params[:user_ids].respond_to?(:each) ? params[:user_ids] : params[:user_ids].split(',')
          access = params[:team_access]
          @team.add_users(user_ids, access)
        end

        receive_delayed_notifications
      end
    end
  end
end
