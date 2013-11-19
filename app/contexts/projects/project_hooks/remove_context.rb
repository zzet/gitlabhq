module Projects
  module ProjectHooks
    class RemoveContext < Projects::ProjectHooks::BaseContext
      def execute
        project_hook.destroy

        receive_delayed_notifications
      end
    end
  end
end
