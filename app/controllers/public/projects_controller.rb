class Public::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
                     :reject_blocked, :set_current_user_for_observers,
                     :add_abilities

  layout 'public'

  def index
    @projects = Project.public_or_internal_only(current_user)
    @sort = params[:sort]
    @projects = @projects.sort(@sort)
    @projects = Project.search(params[:search], options: { pids: @projects.pluck(:id) }, page: params[:page], per: 20).pluck(:id)
    @projects = Project.where(id: @projects).includes(:namespace)
  end
end
