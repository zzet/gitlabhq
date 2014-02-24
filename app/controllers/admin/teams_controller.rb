class Admin::TeamsController < Admin::ApplicationController
  def index
    @teams_count = Team.count
    @teams = Team.search(params[:name], options: params, page: params[:page])
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
    @team ||= Team.find_by(path: params[:id])
  end

end
