class UsersController < ApplicationController
  layout 'navless'

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects
    @events = @user.recent_events.where(project_id: @projects.map(&:id))
    @events = @events.limit(20)

    @title = @user.name
  end
end
