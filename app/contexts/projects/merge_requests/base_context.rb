module Projects
  module MergeRequests
    class BaseContext < Projects::BaseContext
      attr_accessor :project, :current_user, :member, :params

      def initialize(user, project, merge_request, params = {})
        @project, @current_user, @merge_request, @params = project, user, merge_request, params.dup
      end

      def team_member_relation
        @member.users_projects.find_by_project_id(@project)
      end
    end
  end
end
