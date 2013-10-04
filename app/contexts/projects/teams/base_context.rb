module Projects
  module Teams
    class BaseContext < Projects::BaseContext
      attr_accessor :team, :project, :current_user, :params

      def initialize(user, project, team, params = {})
        @current_user, @project, @team, @params = user, project, team, params.dup
      end
    end
  end
end
