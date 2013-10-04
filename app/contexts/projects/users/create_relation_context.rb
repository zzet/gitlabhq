module Projects
  module Users
    class CreateRelationContext < Projects::BaseContext
      def execute
        user_ids = params[:user_ids].respond_to?(:each) ? params[:user_ids] : params[:user_ids].split(',')
        users = User.where(id: user_ids)
        @project.team << [users, params[:project_access]]

        receive_delayed_notifications
      end
    end
  end
end
