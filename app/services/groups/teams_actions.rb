module Groups::TeamsActions
  private

  def assign_team_action
    Group.transaction do
      team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')

      multiple_action("teams_add", "group", group, team_ids) do
        team_ids.each do |team_id|
          group_team_relation = group.team_group_relationships.new(team_id: team_id)
          group_team_relation.save
        end
      end

    end
  end

  def resign_team_action(team)
    multiple_action("teams_remove", "group", group, teams) do
      gtr = group_team_relation(team)
      gtr.destroy
    end
  end

  private

  def group_team_relation(team)
    team.team_group_relationships.find_by(group_id: group)
  end
end
