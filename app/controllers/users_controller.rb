class UsersController < ApplicationController
  layout 'navless'

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @current_user.known_projects.where(id: @user.known_projects)
    @events = @user.recent_events.where(project_id: @projects).limit(params[:limit]).offset(params[:offset])

    @title = @user.name
  end
end
