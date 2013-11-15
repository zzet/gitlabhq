module Projects
  module ProjectHooks
    class BaseContext < Projects::BaseContext
      attr_accessor :project, :current_user, :project_hook, :params

      def initialize(user, project, project_hook, params = {})
        @project, @current_user, @project_hook, @params = project, user, project_hook, params.dup
      end
    end
  end
end
