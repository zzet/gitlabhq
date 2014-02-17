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

    Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)

    Team.where(id: team_ids).find_each do |team|
      Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)
    end

    group.projects.find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end
  end

  def resign_team_action(team)
    multiple_action("teams_remove", "group", group, team) do
      gtr = group_team_relation(team)
      gtr.destroy
    end

    Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)
    Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)

    group.projects.find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end
  end

  private

  def group_team_relation(team)
    team.team_group_relationships.find_by(group_id: group)
  end
end
