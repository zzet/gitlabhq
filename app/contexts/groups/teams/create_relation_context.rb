module Groups
  module Teams
    class CreateRelationContext < Groups::BaseContext
      def execute
        Group.transaction do
          team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')
          team_ids.each do |team_id|
            @group_team_relation = @group.team_group_relationships.new(team_id: team_id)
            @group_team_relation.save
          end

          receive_delayed_notifications
        end
      end
    end
  end
end
