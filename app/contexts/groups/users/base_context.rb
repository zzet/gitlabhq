module Groups
  module Users
    class BaseContext < Groups::BaseContext
      attr_accessor :group, :current_user, :member, :params

      def initialize(user, group, member, params = {})
        @group, @current_user, @member, @params = group, user, member, params.dup
      end

      def group_member_relation
        @member.users_groups.find_by_group_id(@group)
      end
    end
  end
end
