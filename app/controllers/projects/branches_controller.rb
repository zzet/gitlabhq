class Projects::BranchesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create, :destroy]

  def index
    @sort = params[:sort] || 'name'
    @branches = @repository.branches_sorted_by(@sort)
    @branches = Kaminari.paginate_array(@branches).page(params[:page]).per(30)
  end

  def recent
    @branches = @repository.recent_branches
  end

  def create
    ProjectsService.new(current_user, @project, params).repository.create_branch(params[:branch_name], params[:ref])

    redirect_to project_branches_path(@project)
  end

  def destroy
    ProjectsService.new(current_user, @project, params).repository.delete_branch(params[:id])

    respond_to do |format|
      format.html { redirect_to project_branches_path(@project) }
      format.js
    end
  end
end
