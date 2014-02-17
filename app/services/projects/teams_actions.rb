module Projects::TeamsActions
  private

  def assign_team_action
    unless params[:team_ids].blank?
      team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')
      multiple_action("teams_add", "project", project, team_ids) do
        team_ids.each do |team_id|
          project.team_project_relationships.create(team_id: team_id)
        end
      end

      Team.where(id: team_ids).find_each do |team|
        Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)
      end

      project.team.members.find_each do |user|
        Elastic::BaseIndexer.perform_async(:update, user.class.name, user.id)
      end
    end
  end

  def resign_team_action(team)
    TeamsService.new(current_user, team).resign_from_projects(project)
  end
end
