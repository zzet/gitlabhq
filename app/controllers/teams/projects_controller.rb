class Teams::ProjectsController < Teams::ApplicationController
  def index
    projects
    #@avaliable_projects = current_user.admin? ? Project.without_team(team) : current_user.owned_projects.without_team(team)
    @project_relation = team.team_project_relationships.build
    render :index, layout: 'team_settings'
  end

  def create
    redirect_to :back if params[:project_ids].blank?

    ::TeamsService.new(current_user, team, params).assign_on_projects

    redirect_to team_projects_path(team), notice: 'Team of users was successfully assigned to projects.'
  end

  def destroy
    ::TeamsService.new(current_user, team).resign_from_projects(team_project)

    redirect_to team_projects_path(team), notice: 'Team of users was successfully removed from project.'
  end

  private

  def team_project
    @project ||= team.projects.find_with_namespace(params[:id])
  end
end
