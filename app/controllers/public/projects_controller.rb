class Public::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
                     :reject_blocked, :set_current_user_for_observers,
                     :add_abilities

  layout 'public'

  def index
    @sort = params[:sort]
    visibility_levels = [ Gitlab::VisibilityLevel::PUBLIC ]
    visibility_levels << Gitlab::VisibilityLevel::INTERNAL if current_user

    @projects = Project.search(params[:search],
                               options: { visibility_levels: visibility_levels,
                                          order: @sort },
                               page: params[:page],
                               per: 20).records
  end
end
