class UsersController < ApplicationController
  layout 'navless'

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects.where(id: current_user.authorized_projects.pluck(:id)).includes(:namespace)
    @events = @user.recent_events.where(project_id: @projects.map(&:id)).limit(20)

    @projects       = @current_user.known_projects.where(id: @user.authorized_projects)
    @groups         = @current_user.authorized_groups.where(id: @user.personal_groups)
    @teams          = @current_user.authorized_teams.where(id: @user.personal_teams)

    @event_projects = @current_user.known_projects
    @events         = @user.recent_events.where(project_id: @event_projects).reorder('created_at DESC').offset(params[:offset]).limit(params[:limit])

    @title          = @user.name
  end
end
