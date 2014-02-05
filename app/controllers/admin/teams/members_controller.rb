class Admin::Teams::MembersController < Admin::Teams::ApplicationController
  def new
    @users = User.potential_team_members(team)
  end

  def create
    team_service.new(@current_user, team, params).add_memberships

    redirect_to admin_team_path(team), notice: 'Members were successfully added into Team of users.'
  end

  def edit
    team_member
  end

  def update
    if team_service.update_memberships(team_member)
      redirect_to admin_team_path(team), notice: "Membership for #{team_member.name} was successfully updated in Team of users."
    else
      render :edit
    end
  end

  def destroy
    team_service.new(@current_user, team).delete_membership(team_member)

    redirect_to admin_team_path(team), notice: "Member #{team_member.name} was successfully removed from Team of users."
  end

  protected

  def team_member
    @member ||= team.members.find_by_username(params[:id])
  end
end
