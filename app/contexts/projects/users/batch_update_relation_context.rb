module Projects
  module Users
    class BatchUpdateRelationContext < Projects::BaseContext
      def execute
        user_project_ids = params[:ids].respond_to?(:each) ? params[:ids] : params[:ids].split(',')
        UsersProject.where(id: user_project_ids).update_all(project_access: params[:team_member][:project_access])

        receive_delayed_notifications
      end
    end
  end
end
