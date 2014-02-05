class Admin::Teams::ProjectsController < Admin::Teams::ApplicationController
  def new
    @projects = Project.all
    @projects = @projects.without_team(team) if team.projects.any?
    #@projects.reject!(&:empty_repo?)
  end

  def create
    redirect_to :back if params[:project_ids].blank?

    team_service.assign_on_projects(param)

    redirect_to admin_team_path(team), notice: 'Team of users was successfully assigned to projects.'
  end

  def edit
    team_project
  end

  def destroy
    team_service.resign_from_projects(team_project)

    redirect_to admin_team_path(team), notice: 'Team of users was successfully resigned from project.'
  end

  protected

  def team_project
    @project ||= team.projects.find_with_namespace(params[:id])
  end
end
