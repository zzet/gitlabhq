class Projects::EditTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :blob
  before_filter :authorize_push!

  def show
    @last_commit = Gitlab::Git::Commit.last_for_path(@repository, @ref, @path).sha
  end

  def update
    result = ProjectsService.new(current_user, @project, params).repository.update_file(@ref, @path)

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      redirect_to project_blob_path(@project, @id)
    else
      flash[:alert] = result[:error]
      render :show
    end
  end

  def preview
    @content = params[:content]
    #FIXME workaround https://github.com/gitlabhq/gitlabhq/issues/5939
    @content += "\n" if @blob.data.end_with?("\n")

    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3', include_diff_info: true)
    @diff = Gitlab::Diff::DiffyParser.new(diffy)

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)
  end
end
