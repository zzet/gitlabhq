module Teams
  module Groups
    class CreateRelationContext < Teams::Groups::BaseContext
      def execute
        permission = params[:greatest_project_access]

        team.team_group_relationship.create(group_id: group, greatest_access: permission)

        receive_delayed_notifications
      end
    end
  end
end
