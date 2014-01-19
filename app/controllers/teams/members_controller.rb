class Teams::MembersController < Teams::ApplicationController
  def index
    @members = team.team_user_relationships
    @user_relation = team.team_user_relationships.build
    render :index, layout: 'team_settings'
  end

  def create
    ::TeamsService.new(@current_user, team, params).add_memberships

    redirect_to team_members_path(team), notice: 'Members were successfully added into Team of users.'
  end

  def update
    if ::TeamsService.new(@current_user, team, params[:team_user_relationship]).update_memberships(team_member)
      redirect_to team_members_path(team), notice: "Membership for #{team_member.name} was successfully updated in Team of users."
    else
      redirect_to team_members_path(team), notice: "Membership for #{team_member.name} was nat updated in Team of users."
    end
  end

  def destroy
    ::TeamsService.new(@current_user, team).delete_membership(team_member)
    redirect_to team_members_path(team), notice: "Member #{team_member.name} was successfully removed from Team of users."
  end

  protected

  def team_member
    @member ||= team.members.find_by_username(params[:id])
  end
end
