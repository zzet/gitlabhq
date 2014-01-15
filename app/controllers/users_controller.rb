class UsersController < ApplicationController
  layout 'navless'

  def show
    @user           = User.find_by_username!(params[:username])

    @projects       = @current_user.known_projects.where(id: @user.authorized_projects).includes(:namespace).sort_by do |p|
      p.namespace.human_name
    end
    @groups         = @current_user.authorized_groups.where(id: @user.personal_groups)
    @teams          = @current_user.authorized_teams.where(id: @user.personal_teams)

    @event_projects = @current_user.known_projects
    @events         = @user.recent_events.where(project_id: @event_projects).reorder('created_at DESC').offset(params[:offset]).limit(params[:limit])

    @title          = @user.name
  end
end
