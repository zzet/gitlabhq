module Projects
  module Users
    class BatchRemoveRelationContext < Projects::BaseContext
      def execute
        user_project_ids = params[:ids].respond_to?(:each) ? params[:ids] : params[:ids].split(',')
        user_project_relations = UsersProject.where(id: user_project_ids)

        user_project_relations.destroy_all

        receive_delayed_notifications
      end
    end
  end
end
