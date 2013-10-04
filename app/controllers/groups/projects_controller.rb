class Groups::ProjectsController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @projects = group.projects
    render :index, layout: 'group_settings'
  end
end
