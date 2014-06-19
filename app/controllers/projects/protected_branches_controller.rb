class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_filter :require_non_empty_project
  before_filter :authorize_admin_project!

  layout "project_settings"

  def index
    @branches = @project.protected_branches.to_a
    @protected_branch = @project.protected_branches.new
  end

  def create
    branch = params[:protected_branch][:name]
    ProjectsService.new(current_user, @project).repository.protect_branch(branch)
    redirect_to project_protected_branches_path(@project)
  end

  def destroy
    branch = @project.protected_branches.find(params[:id])
    ProjectsService.new(current_user, @project).repository.unprotect_branch(branch.name)

    respond_to do |format|
      format.html { redirect_to project_protected_branches_path }
      format.js { render nothing: true }
    end
  end
end
