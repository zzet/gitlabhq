class Admin::Teams::MembersController < Admin::Teams::ApplicationController
  def new
    @users = User.potential_team_members(team)
  end

  def create
    ::Teams::Users::CreateRelationContext.new(@current_user, team, params).execute

    redirect_to admin_team_path(team), notice: 'Members were successfully added into Team of users.'
  end

  def edit
    team_member
  end

  def update
    if ::Teams::Users::UpdateRelationContext.new(@current_user, team, team_member, params).execute
      redirect_to admin_team_path(team), notice: "Membership for #{team_member.name} was successfully updated in Team of users."
    else
      render :edit
    end
  end

  def destroy
    ::Teams::Users::RemoveRelationContext.new(@current_user, team, team_member).execute

    redirect_to admin_team_path(team), notice: "Member #{team_member.name} was successfully removed from Team of users."
  end

  protected

  def team_member
    @member ||= team.members.find_by_username(params[:id])
  end
end
