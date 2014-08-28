class SearchController < ApplicationController
  include SearchHelper

  def show
    @group   = Group.find_by(id: params[:group_id])     if params[:group_id].present?

    if project
      return access_denied! unless can?(current_user, :download_code, project)
      @search_results = SearchService.new(current_user, params).project_search(project)
    else
      @search_results = SearchService.new(current_user, params).global_search
    end

    @search_results = SearchDecorator.new(@search_results, params[:type])
  end

  def autocomplete
    term = params[:term]

    render json: search_autocomplete_opts(term)
  end

  private

  def project
    @project ||= Project.find_with_namespace(params.fetch(:project, ''))
  end
end
