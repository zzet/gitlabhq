class Teams::GroupsController < Teams::ApplicationController
  #skip_before_filter :authorize_manage_team!, only: [:index]

  def index
    groups
    @avaliable_groups = current_user.admin? ? current_user.owned_groups.without_team(team) : Group.without_team(team)
    @group_relation   = team.team_group_relationships.build
    render :index, layout: 'team_settings'
  end

  def create
    ::Teams::Groups::CreateRelationContext.new(@current_user, team, params).execute

    redirect_to team_groups_path(team), notice: 'Groups were successfully added into Team of users.'
  end

  def destroy
    ::Teams::Groups::RemoveRelationContext.new(@current_user, team, group).execute
    redirect_to team_groups_path(team), notice: "Group #{group.name} was successfully removed from Team of users."
  end

  protected

  def group
    @group ||= team.groups.find_by_path(params[:id])
  end
end
