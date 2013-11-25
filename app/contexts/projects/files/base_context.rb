module Projects
  module Files
    class BaseContext < ::Projects::BaseContext
      attr_reader :ref, :path

      def initialize(user, project, params, ref, path = nil)
        @project, @current_user, @params = project, user, params.dup
        @ref = ref
        @path = path
      end

      private

      def error(message)
        {
          error: message,
          status: :error
        }
      end

      def success
        {
          error: '',
          status: :success
        }
      end

      def repository
        project.repository
      end
    end
  end
end
