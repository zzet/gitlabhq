module Groups::TeamsActions
  private

  def assign_team_action
    team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')

    Group.transaction do
      multiple_action("teams_add", "group", group, team_ids) do
        team_ids.each do |team_id|
          group_team_relation = group.team_group_relationships.new(team_id: team_id)
          group_team_relation.save
        end
      end
    end

    team_ids.each do |team_id|
      reindex_with_elastic(:update, Team.name, team_id)
    end

    update_group_projects_indexes(group)
  end

  def resign_team_action(team)
    multiple_action("teams_remove", "group", group, team) do
      gtr = group_team_relation(team)
      gtr.destroy
    end

    reindex_with_elastic(:update, Team.name, team.id)

    update_group_projects_indexes(group)
  end

  private

  def group_team_relation(team)
    team.team_group_relationships.find_by(group_id: group)
  end

  def update_group_projects_indexes(group)
    group.projects.pluck(:id).each do |project_id|
      reindex_with_elastic(:update, Project.name, project_id)
    end
  end
end
