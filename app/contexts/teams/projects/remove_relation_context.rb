module Teams
  module Projects
    class RemoveRelationContext < Teams::Projects::BaseContext
      def execute
        Gitlab::UserTeamManager.resign(team, project)

        receive_delayed_notifications
      end
    end
  end
end
