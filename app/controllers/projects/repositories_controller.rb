class Projects::RepositoriesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def stats
    @stats = Gitlab::Git::Stats.new(@repository.raw, @repository.root_ref)
    @graph = @stats.graph
  end

  def archive
    unless can?(current_user, :download_code, @project)
      render_404 and return
    end

    result = Projects::Repositories::Archive.perform(project: @project,
                                                     ref: params[:ref],
                                                     format: params[:format])

    if result.success?
      file_path = result[:file_path]
      # Send file to user
      response.headers["Content-Length"] = File.open(file_path).size.to_s
      send_file file_path
    else
      render_404
    end
  end
end
