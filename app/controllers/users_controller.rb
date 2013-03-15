class UsersController < ApplicationController
  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects.merge(Project.public_only)
    @events = @user.recent_events.where(project_id: @projects.map(&:id))
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
