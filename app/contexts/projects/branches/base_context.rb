module Projects
  module Branches
    class BaseContext < Projects::BaseContext
      attr_accessor :current_user, :project, :branch, :params

      def initialize(user, project, branch, params = {})
        @current_user, @project, @branch, @params = user, project, branch, params
      end
    end
  end
end
