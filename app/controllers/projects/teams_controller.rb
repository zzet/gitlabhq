class Projects::TeamsController < Projects::ApplicationController

  before_filter :authorize_admin_team_member!

  def index
    @teams = project.teams
    @team_project_relation = project.team_project_relationships.build
    @avaliable_teams = current_user.authorized_teams.where("id not in (?)", @teams.pluck(:id) + project.group_teams.pluck(:id))
    render :index, layout: 'project_settings'
  end

  def create
    ::Project::Teams::CreateRelationContext.new(@current_user, project, params).execute

    redirect_to project_teams_path(@project)
  end

  def destroy
    ::Project::Teams::RemoveRelationContext.new(@current_user, project, team).execute

    redirect_to project_teams_path(@project)
  end

  protected

  def team
    @team ||= Team.find_by_path(params[:id])
  end
end
