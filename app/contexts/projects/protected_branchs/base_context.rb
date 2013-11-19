module Projects
  module ProtectedBranchs
    class BaseContext < Projects::BaseContext
      attr_accessor :project, :current_user, :protected_branch, :params

      def initialize(user, project, protected_branch, params = {})
        @project, @current_user, @protected_branch, @params = project, user, protected_branch, params.dup
      end
    end
  end
end
