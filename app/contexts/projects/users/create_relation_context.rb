module Projects
  module Users
    class CreateRelationContext < Projects::BaseContext
      def execute
        users = User.where(id: params[:user_ids].split(','))
        @project.team << [users, params[:project_access]]

        receive_delayed_notifications
      end
    end
  end
end
