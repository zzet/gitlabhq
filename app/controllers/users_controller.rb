class UsersController < ApplicationController
  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects
    @events = @user.recent_events.where(project_id: @projects.map(&:id)).limit(20)
  end
end
