module Projects
  module Users
    class ImportRelationContext < Projects::BaseContext
      def execute
        giver = Project.find(params[:source_project_id])

        RequestStore.store[:borders] ||= []
        RequestStore.store[:borders].push("gitlab.import.project")
        Gitlab::Event::Action.trigger :import, @project

        status = @project.team.import(giver)

        RequestStore.store[:borders].pop

        receive_delayed_notifications

        status
      end
    end
  end
end
