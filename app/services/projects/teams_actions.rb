module Projects::TeamsActions
  private

  def assign_team_action
    unless params[:team_ids].blank?
      team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')
      team_ids.each do |team_id|
        team = Team.find(team_id)
        params[:project_ids] = [project.id]
        TeamsService.new(current_user, team, params).assign_on_projects
      end
    end
  end

  def resign_team_action(team)
    TeamsService.new(current_user, team).resign_from_projects(project)
  end
end
