class Admin::TeamsController < Admin::ApplicationController
  def index
    @teams = Team.order('name ASC')
    @teams_count = @teams.count

    if params[:member].present?
      user = User.find_by_username(params[:member])
      team_ids = TeamUserRelationship.where(user_id: user).pluck(:team_id)
      @teams = @teams.where(id: team_ids)
    end

    if params[:owner].present?
      user = User.find_by_username(params[:owner])
      team_ids = TeamUserRelationship.where(user_id: user).pluck(:team_id)
      @teams = @teams.where(id: team_ids)
    end

    if params[:group].present?
      group = Group.find_by_path(params[:group])
      team_ids = TeamGroupRelationship.where(group_id: group).pluck(:team_id)
      @teams = @teams.where(id: team_ids)
    end

    if params[:project].present?
      project = Project.find_with_namespace(params[:project])
      team_ids = TeamProjectRelationship.where(project_id: project).pluck(:team_id)
      @teams = @teams.where(id: team_ids)
    end

    user_ids = TeamUserRelationship.where(team_id: @teams).pluck(:user_id)
    @users = User.where(id: user_ids).active.order('name ASC')

    group_ids = TeamGroupRelationship.where(team_id: @teams).pluck(:group_id)
    @groups = Group.where(id: group_ids).order("name ASC")

    project_ids = TeamProjectRelationship.where(team_id: @teams).pluck(:project_id)
    @projects = Project.where(id: project_ids).includes(:namespace).order("namespaces.name, projects.name ASC")

    @teams = @teams.search(params[:name]) if params[:name].present?
    @teams = @teams.page(params[:page]).per(20)
  end

  def show
    team
  end

  def new
    @team = Team.new
  end

  def edit
    team
  end

  def create
    @team = TeamsService.new(current_user, params[:team]).create

    if @team.persisted?
      redirect_to admin_team_path(@team), notice: 'Team of users was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    team_params = params[:team].dup
    owner_id = team_params.delete(:owner_id)

    if owner_id
      team.owner = User.find(owner_id)
    end

    if team.update(team_params)
      redirect_to admin_team_path(team), notice: 'Team of users was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    ::TeamsService.new(current_user, team).delete

    redirect_to admin_teams_path, notice: 'Team of users was successfully deleted.'
  end

  protected

  def team
    @team ||= Team.find_by_path(params[:id])
  end

end
