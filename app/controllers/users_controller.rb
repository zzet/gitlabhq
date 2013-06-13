class UsersController < ApplicationController
  layout 'navless'

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @current_user.authorized_projects.where(id: @user.authorized_projects)
    @events = @user.recent_events.where(project_id: @projects.map(&:id))
    @events = @events.limit(20)

    @title = @user.name
  end
end
