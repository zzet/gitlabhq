class Teams::GroupsController < Teams::ApplicationController
  #skip_before_filter :authorize_manage_team!, only: [:index]

  def index
    groups
    @avaliable_groups = current_user.admin? ? current_user.owned_groups.without_team(team) : Group.without_team(team)
    @group_relation   = team.team_group_relationships.build
    render :index, layout: 'team_settings'
  end

  def create
    ::Teams::Users::CreateRelationContext.new(@current_user, team, params).execute

    redirect_to team_members_path(team), notice: 'Members were successfully added into Team of users.'
  end

  def destroy
    ::Teams::Users::RemoveRelationContext.new(@current_user, team, team_member).execute
    redirect_to team_path(team), notice: "Member #{team_member.name} was successfully removed from Team of users."
  end

  protected

  def team_member
    @member ||= team.members.find_by_username(params[:id])
  end
end
