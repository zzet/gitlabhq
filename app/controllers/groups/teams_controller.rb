class Groups::TeamsController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @teams = group.teams
    @team_group_relation = group.team_group_relationships.build
    #@avaliable_teams = current_user.authorized_teams
    #@avaliable_teams = @avaliable_teams.where.not(id: @teams.pluck(:id)) if @teams.any?
    render :index, layout: 'group_settings'
  end

  def create
    ::GroupsService.new(@current_user, group, params).assign_team

    redirect_to group_teams_path(@group)
  end

  def destroy
    ::GroupsService.new(@current_user, group).resign_team(team)

    redirect_to group_teams_path(@group)
  end
  protected

  def team
    @team ||= (params[:id].present? ? Team.find_by(path: params[:id]) : Team.find(params[:team_id]))
  end
end
