class Groups::TeamsController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @teams = group.teams
    @team_group_relation = group.team_group_relationships.build
    @avaliable_teams = current_user.authorized_teams.where("id not in (?)", @teams.pluck(:id))
    render :index, layout: 'group_settings'
  end

  def create
    ::Groups::Teams::CreateRelationContext.new(@current_user, group, params).execute

    redirect_to group_teams_path(@group)
  end

  def destroy
    ::Groups::Teams::RemoveRelationContext.new(@current_user, group, team).execute

    redirect_to group_teams_path(@group)
  end
  protected

  def team
    @team ||= (params[:id].present? ? Team.find_by_path(params[:id]) : Team.find(params[:team_id]))
  end
end
