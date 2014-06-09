class Admin::GroupsController < Admin::ApplicationController
  before_filter :group, only: [:edit, :show, :update, :destroy, :project_update, :project_teams_update]

  def index
    @groups = Group.search(params[:name], page: params[:page]).records
  end

  def show
    @group_projects = @group.projects
    @members = @group.users
    @teams = @group.teams

    @projects = Project.all
    @projects = @projects.not_in_group(@group) if @group.projects.present?
    @projects.reject!(&:empty_repo?)

    @users = User.active
    @available_teams = group.teams.any? ? Team.where.not(id: group.teams.pluck(:id)) : Team.all

    session[:redirect_to] = admin_group_path(@group)
    #@members = @group.members.order("group_access DESC").page(params[:members_page]).per(30)
    #@projects = @group.projects.page(params[:projects_page]).per(30)
  end

  def new
    @group = ::Group.new
  end

  def edit
  end

  def create
    @group = ::GroupsService.new(current_user, params[:group]).create

    if @group.persisted?
      redirect_to [:admin, @group], notice: 'Group was successfully created.'
    else
      render "new"
    end
  end

  def update
    if @group.update_attributes(params[:group])
      redirect_to [:admin, @group], notice: 'Group was successfully updated.'
    else
      render "edit"
    end
  end


  def project_teams_update
    @group.add_users(params[:user_ids].split(','), params[:group_access])

    redirect_to [:admin, @group], notice: 'Users were successfully added.'
  end

  def destroy
    ::GroupsService.new(current_user, group).delete

    redirect_to admin_groups_path, notice: 'Group was successfully deleted.'
  end

  private

  def group
    @group = Group.find_by(path: params[:id])
  end
end
