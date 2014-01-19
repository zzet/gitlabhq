class SearchController < ApplicationController
  def show
    @project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
    @group = Group.find_by(id: params[:group_id])       if params[:group_id].present?

    if @project
      return access_denied! unless can?(current_user, :download_code, @project)
      @search_results = SearchService.new(current_user, params).project_search(@project)
    else
      @search_results = SearchService.new(current_user, params).global_search
    end
  end
end
