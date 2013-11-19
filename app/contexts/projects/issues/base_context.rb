module Projects
  module Issues
    class BaseContext < Projects::BaseContext
      attr_accessor :project, :current_user, :issue, :params

      def initialize(user, project, issue, params = {})
        @project, @current_user, @issue, @params = project, user, issue, params.dup
      end
    end
  end
end
