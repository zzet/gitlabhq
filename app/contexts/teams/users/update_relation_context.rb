module Teams
  module Users
    class UpdateRelationContext < Teams::Users::BaseContext
      def execute

        options = {
          default_projects_access: params[:permission],
          group_admin: params[:group_admin] || 0
        }

        result = @team.update_membership(@user, options)

        receive_delayed_notifications

        result
      end
    end
  end
end
