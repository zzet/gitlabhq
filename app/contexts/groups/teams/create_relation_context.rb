module Groups
  module Teams
    class CreateRelationContext < Groups::BaseContext
      def execute
        team_ids = params[:user_ids].split(',')
        team_ids.each do |team_id|
          @group_team_relation = @group.team_group_relationships.new(team_id: team_id)
          if @group_team_relation.save
            receive_delayed_notifications
          end
        end
      end
    end
  end
end
