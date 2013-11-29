class Projects::TagsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create]
  before_filter :authorize_admin_project!, only: [:destroy]

  rescue_from Errno::EISDIR, with: :gc_in_repository

  def index
    @tags = Kaminari.paginate_array(@repository.tags).page(params[:page]).per(30)
  end

  def create
    Projects::Tags::CreateContext.new(current_user, @project, params).execute

    redirect_to project_tags_path(@project)
  end

  def destroy
    tag = @repository.find_tag(params[:id])

    Projects::Tags::RemoveContext.new(current_user, @project, tag).execute

    respond_to do |format|
      format.html { redirect_to project_tags_path }
      format.js { render nothing: true }
    end
  end

  private

  def gc_in_repository
    @repository.raw.git.gc
    redirect_to tags_project_path(@project)
  end
end
