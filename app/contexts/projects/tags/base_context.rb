module Projects
  module Tags
    class BaseContext < Projects::BaseContext
      attr_accessor :current_user, :project, :tag, :params

      def initialize(user, project, tag, params = {})
        @current_user, @project, @tag, @params = user, project, tag, params
      end
    end
  end
end
