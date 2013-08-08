module Projects
  module Users
    class BaseContext < Projects::BaseContext
      attr_accessor :project, :current_user, :member, :params

      def initialize(user, project, member, params = {})
        @project, @current_user, @member, @params = project, user, member, params.dup
      end

      def team_member_relation
        @member.users_projects.find_by_project_id(@project)
      end
    end
  end
end
