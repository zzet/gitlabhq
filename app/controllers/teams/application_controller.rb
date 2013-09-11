class Teams::ApplicationController < ApplicationController

  layout 'team'

  #before_filter :authorize_manage_team!

  protected

  def projects
    @projects ||= team.projects.sorted_by_push_date
  end

  def groups
    @groups ||= team.groups
  end

  def members
    @members ||= team.members
  end

  def team
    @team ||= Team.find_by_path(params[:team_id])
  end
end
