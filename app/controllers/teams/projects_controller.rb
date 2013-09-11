class Teams::ProjectsController < Teams::ApplicationController
  def index
    projects
    @avaliable_projects = current_user.owned_projects.without_team(team)
    @project_relation = team.team_project_relationships.build
    render :index, layout: 'team_settings'
  end

  def create
    redirect_to :back if params[:project_ids].blank?

    ::Teams::Projects::CreateRelationContext.new(current_user, team, params).execute

    redirect_to edit_team_path(team), notice: 'Team of users was successfully assigned to projects.'
  end

  def destroy
    ::Teams::Projects::RemoveRelationContext.new(current_user, team, team_project, params).execute

    redirect_to team_path(team), notice: 'Team of users was successfully reassigned from project.'
  end

  private

  def team_project
    @project ||= team.projects.find_with_namespace(params[:id])
  end
end
