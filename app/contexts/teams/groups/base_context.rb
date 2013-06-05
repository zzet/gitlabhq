module Teams
  module Groups
    class BaseContext < Teams::BaseContext
      attr_accessor :team, :group, :current_user, :params

      def initialize(user, team, group, params = {})
        @current_user, @team, @group, @params = user, team, group, params.dup
      end
    end
  end
end
