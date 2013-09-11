class Groups::TeamsController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @teams = group.teams
  end

  def new
    @available_teams = current_user.admin? ? (group.teams.any? ? Team.where("id not in (?)", group.teams) : Team.scoped) : current_user.authorized_teams
    session[:redirect_to] = request.referer
    if @available_teams.blank?
      flash[:notice] = "No available teams for adding to group"
      redirect_to :back
    end
  end

  def create
    ::Teams::Groups::CreateRelationContext.new(current_user, team, group, params).execute

    flash[:notice] = "Team successful added to group"
    redirect_back_or_default(action: :index)
  end

  def update
    ::Teams::Groups::UpdateRelationContext.new(current_user, team, group, params).execute

    redirect_to :back
  end

  def destroy
    ::Teams::Groups::RemoveRelationContext.new(current_user, team, group).execute

    flash[:notice] = "Team successful removed from group"
    redirect_to :back
  end

  def edit
    group
    team
  end

  protected

  def team
    @team ||= (params[:id].present? ? Team.find_by_path(params[:id]) : Team.find(params[:team_id]))
  end
end
