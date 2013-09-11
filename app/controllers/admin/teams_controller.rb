class Admin::TeamsController < Admin::ApplicationController
  def index
    @teams = Team.order('name ASC')
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
    @team = Team.new(params[:team])
    @team.path = @team.name.dup.parameterize if @team.name
    @team.owner = current_user

    if @team.save
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

    if team.update_attributes(team_params)
      redirect_to admin_team_path(team), notice: 'Team of users was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    ::Teams::RemoveContext.new(current_user, team).execute

    redirect_to admin_teams_path, notice: 'Team of users was successfully deleted.'
  end

  protected

  def team
    @team ||= Team.find_by_path(params[:id])
  end

end
