class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:edit, :show, :update, :destroy, :team_update]

  def index
    owner_id = params[:owner_id]
    user = User.find_by_id(owner_id)

    @projects = user ? user.owned_projects : Project.scoped
    @projects = @projects.where(public: true) if params[:public_only].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
    check_git_protocol
  end

  def show
    @repository = @project.repository
    @group = @project.group

    @users = User.active
    @users = @users.not_in_project(@project) if @project.users.present?
    check_git_protocol
  end

  def destroy
    ::Projects::RemoveContext.new(current_user, project).execute
    redirect_to admin_projects_path
  end

  protected

  def project
    id = params[:project_id] || params[:id]

    @project = Project.find_with_namespace(id)
    @project || render_404
  end

  def check_git_protocol
    @git_protocol_enabled ||= Gitlab.config.gitlab.git_daemon_enabled
  end
end
