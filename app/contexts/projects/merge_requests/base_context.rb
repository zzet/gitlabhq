module Projects
  module MergeRequests
    class BaseContext < Projects::BaseContext
      attr_accessor :project, :current_user, :merge_request, :params

      def initialize(user, project, merge_request, params = {})
        @project, @current_user, @merge_request, @params = project, user, merge_request, params.dup
      end
    end
  end
end
