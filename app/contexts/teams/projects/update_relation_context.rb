module Teams
  module Projects
    class UpdateRelationContext < Teams::Projects::BaseContext
      def execute
        permission = params[:greatest_project_access]
        relation = team.team_project_relationships.find_by_project_id(project)

        if relation.present?
          relation.update_attributes(greatest_access: access)
        end

        receive_delayed_notifications
      end
    end
  end
end
