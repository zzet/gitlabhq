# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::Teams::ApplicationController < Admin::ApplicationController

  private

  def team
    @team = Team.find_by_path(params[:team_id])
  end

  def team_service
    ::TeamsService.new(@current_user, team, params)
  end
end
