module Projects
  module Users
    class BatchUpdateRelationContext < Projects::BaseContext
      def execute
        user_project_ids = params[:ids].respond_to?(:each) ? params[:ids] : params[:ids].split(',')
        UsersProject.update(user_project_ids, params[:team_member])

        receive_delayed_notifications
      end
    end
  end
end
