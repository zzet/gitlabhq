module Groups::TeamsActions
  private

  def assign_team_action
    Group.transaction do
      team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')
      team_ids.each do |team_id|
        group_team_relation = group.team_group_relationships.new(team_id: team_id)
        group_team_relation.save
      end

      receive_delayed_notifications
    end
  end

  def resign_team_action(team)
    gtr = group_team_relation(team)
    gtr.destroy
    receive_delayed_notifications
  end

  private

  def group_team_relation(team)
    team.team_group_relationships.find_by(group_id: group)
  end
end
