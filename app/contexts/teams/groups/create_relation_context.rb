module Teams
  module Groups
    class CreateRelationContext < Teams::BaseContext
      def execute
        group_ids = params[:group_ids].respond_to?(:each) ? params[:group_ids] : params[:group_ids].split(',')

        unless current_user.admin?
          allowed_group_ids = (current_user.created_groups.pluck(:id) + current_user.owned_groups.pluck(:id)).uniq
          group_ids.select! { |id| allowed_group_ids.include?(id.to_i) }
        end

        group_ids.each do |group|
          team.team_group_relationships.create(group_id: group)
        end

        receive_delayed_notifications
      end
    end
  end
end
