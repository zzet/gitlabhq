class Projects::TeamsController < Projects::ApplicationController

  before_filter :authorize_admin_team_member!

  def index
    @teams = project.teams
    @team_project_relation = project.team_project_relationships.build
    not_avaliable_teams = (@teams.pluck(:id) + project.group_teams.pluck(:id)).uniq
    @avaliable_teams = current_user.authorized_teams
    @avaliable_teams = @avaliable_teams.where("teams.id not in (?)", not_avaliable_teams) if not_avaliable_teams.any?
    render :index, layout: 'project_settings'
  end

  def create
    ::ProjectsService.new(@current_user, project, params).assign_team

    redirect_to project_teams_path(@project)
  end

  def destroy
    ::ProjectsService.new(@current_user, project).resign_team(team)

    redirect_to project_teams_path(@project)
  end

  protected

  def team
    @team ||= project.teams.find_by_path(params[:id])
  end
end
