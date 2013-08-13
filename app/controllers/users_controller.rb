class UsersController < ApplicationController
  layout 'navless'

  def show
    @user           = User.find_by_username!(params[:username])

    @projects       = @current_user.known_projects.where(id: @user.authorized_projects)
    @groups         = @current_user.authorized_groups.where(id: @user.authorized_groups)
    @teams          = @current_user.authorized_teams.where(id: @user.authorized_teams)

    @event_projects = @current_user.known_projects
    @events         = @user.recent_events.where(project_id: @event_projects).limit(params[:limit]).offset(params[:offset])

    @title          = @user.name
  end
end
