module Groups
  module Teams
    class BaseContext < Groups::BaseContext
      attr_accessor :project, :current_user, :team, :params

      def initialize(user, group, team, params = {})
        @group, @current_user, @team, @params = group, user, team, params.dup
      end

      def group_team_relation
        @team.team_group_relationships.find_by_group_id(@group)
      end
    end
  end
end
