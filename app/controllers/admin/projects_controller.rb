class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:show, :transfer]
  before_filter :group, only: [:show, :transfer]
  before_filter :repository, only: [:show, :transfer]

  def index
    @projects = Project.search(params[:name], options: params, page: params[:page]).records

    check_git_protocol
  end

  def show
    if @group
      @group_members = @group.members.order("group_access DESC").page(params[:group_members_page]).per(30)
    end

    @project_members = @project.users_projects.page(params[:project_members_page]).per(30)

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
