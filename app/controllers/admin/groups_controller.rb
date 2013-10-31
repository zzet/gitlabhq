class Admin::GroupsController < Admin::ApplicationController
  before_filter :group, only: [:edit, :show, :update, :destroy, :project_update, :project_teams_update]

  def index
    @groups = ::Group.order('name ASC')
    @groups = @groups.search(params[:name]) if params[:name].present?
    @groups = @groups.page(params[:page]).per(20)
  end

  def show
    @group_projects = @group.projects
    @members = @group.users
    @teams = @group.teams

    @projects = Project.scoped
    @projects = @projects.not_in_group(@group) if @group.projects.present?
    @projects = @projects.all
    @projects.reject!(&:empty_repo?)

    @users = User.active
    @available_teams = group.teams.any? ? Team.where("id not in (?)", group.teams) : Team.scoped

    session[:redirect_to] = admin_group_path(@group)
  end

  def new
    @group = ::Group.new
  end

  def edit
  end

  def create
    @group = ::Group.new(params[:group])
    @group.path = @group.name.dup.parameterize if @group.name

    if @group.save
      @group.add_owner(current_user)
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
    ::Groups::RemoveContext.new(current_user, group).execute

    redirect_to admin_groups_path, notice: 'Group was successfully deleted.'
  end

  private

  def group
    @group = ::Group.find_by_path(params[:id])
  end
end
