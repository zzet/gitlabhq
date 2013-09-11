module Teams
  module Groups
    class UpdateRelationContext < Teams::Groups::BaseContext
      def execute
        permission = params[:greatest_project_access]

        team.team_group_relationship.find_by_group_id(group).updated_attributes(greates_access: permission)

        receive_delayed_notifications
      end
    end
  end
end
