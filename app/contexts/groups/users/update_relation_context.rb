module Groups
  module Users
    class UpdateRelationContext < Groups::Users::BaseContext
      def execute
        group_member_relation.update_attributes(params)

        if group_member_relation.valid?
          receive_delayed_notifications
          return true
        else
          return false
        end
      end
    end
  end
end
