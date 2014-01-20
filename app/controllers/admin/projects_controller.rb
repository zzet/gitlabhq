class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:show, :transfer]
  before_filter :group, only: [:show, :transfer]
  before_filter :repository, only: [:show, :transfer]

  def index
    owner_id = params[:owner_id]
    user = User.find_by_id(owner_id)

    @projects = user ? user.owned_projects : Project.all
    @projects = @projects.where("visibility_level IN (?)", params[:visibility_levels]) if params[:visibility_levels].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
    check_git_protocol
  end

  def show
    @users = User.active
    @users = @users.not_in_project(@project) if @project.users.present?
    check_git_protocol
  end

  def destroy
    ::ProjectsService.new(current_user, project).delete
    redirect_to admin_projects_path
  end

  def transfer
    result = ::ProjectsService.new(current_user, @project, project: params).transfer(:admin)

    if result
      redirect_to [:admin, @project]
    else
      render :show
    end
  end

  protected

  def project
    id = params[:project_id] || params[:id]

    @project = Project.find_with_namespace(id)
    @project || render_404
  end

  def group
    @group ||= project.group
  end

  def repository
    @repository ||= project.repository
  end

  def check_git_protocol
    @git_protocol_enabled ||= Gitlab.config.gitlab.git_daemon_enabled
  end
end
