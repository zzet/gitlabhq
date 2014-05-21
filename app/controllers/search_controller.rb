class SearchController < ApplicationController
  include SearchHelper

  def show
    @project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
    @group   = Group.find_by(id: params[:group_id])     if params[:group_id].present?

    if @project
      return access_denied! unless can?(current_user, :download_code, @project)
      @search_results = SearchService.new(current_user, params).global_search
      #@search_results = SearchService.new(current_user, params).project_search(@project)
    else
      @search_results = SearchService.new(current_user, params).global_search
    end
  end

  def autocomplete
    term = params[:term]

    if params[:project_id].present?
      project = Project.find(params[:project_id])

      render json: search_autocomplete_opts(term, project)
    else
      render json: search_autocomplete_opts(term)
    end
  end
end
