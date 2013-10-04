class Admin::Teams::ProjectsController < Admin::Teams::ApplicationController
  def new
    @projects = Project.scoped
    @projects = @projects.without_team(team) if team.projects.any?
    #@projects.reject!(&:empty_repo?)
  end

  def create
    redirect_to :back if params[:project_ids].blank?

    ::Teams::Projects::CreateRelationContext.new(current_user, team, params).execute

    redirect_to admin_team_path(team), notice: 'Team of users was successfully assigned to projects.'
  end

  def edit
    team_project
  end

  def update
    if ::Teams::Projects::UpdateRelationContext.new(current_user, team, team_project, params).execute
      redirect_to admin_team_path(team), notice: 'Access was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    ::Teams::Projects::RemoveRelationContext.new(current_user, team, team_project, params).execute

    redirect_to admin_team_path(team), notice: 'Team of users was successfully reassigned from project.'
  end

  protected

  def team_project
    @project ||= team.projects.find_with_namespace(params[:id])
  end

end
