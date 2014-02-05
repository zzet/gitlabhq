class Teams::GroupsController < Teams::ApplicationController
  def index
    groups
    #@avaliable_groups = current_user.admin? ? Group.without_team(team) : current_user.owned_groups.without_team(team)
    @group_relation   = team.team_group_relationships.build
    render :index, layout: 'team_settings'
  end

  def create
    ::TeamsService.new(@current_user, team, params).assign_on_groups

    redirect_to team_groups_path(team), notice: 'Groups were successfully added into Team of users.'
  end

  def destroy
    ::TeamsService.new(@current_user, team).resign_from_groups(group)
    redirect_to team_groups_path(team), notice: "Group #{group.name} was successfully removed from Team of users."
  end

  protected

  def group
    @group ||= team.groups.find_by_path(params[:id])
  end
end
