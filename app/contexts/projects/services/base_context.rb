module Projects
  module Services
    class BaseContext < ::BaseContext
      attr_accessor :service, :project, :current_user, :params

      def initialize(user, project, service, params = {})
        @service, @project, @current_user, @params = service, project, user, params.dup
      end
    end
  end
end
