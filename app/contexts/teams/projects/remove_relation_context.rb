module Teams
  module Projects
    class RemoveRelationContext < Teams::Projects::BaseContext
      def execute
        team.team_project_relationships.where(project_id: project).destroy_all

        receive_delayed_notifications
      end
    end
  end
end
