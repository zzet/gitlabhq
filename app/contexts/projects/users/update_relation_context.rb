module Projects
  module Users
    class UpdateRelationContext < Projects::Users::BaseContext
      def execute
        @user_project_relation = project.users_projects.find_by_user_id(member)
        @user_project_relation.update_attributes(params[:team_member])

        if @user_project_relation.valid?
          receive_delayed_notifications
          return true
        else
          return false
        end
      end
    end
  end
end
