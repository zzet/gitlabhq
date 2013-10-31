class SearchController < ApplicationController
  def show
    result = SearchContext.new(@current_user, params).execute

    @project        = result[:project]    if result[:blobs].any?
    @project        = params[:project_id] if params[:project_id].present?

    @group          = params[:group_id]   if params[:group_id].present?

    @projects       = result[:projects]
    @merge_requests = result[:merge_requests]
    @issues         = result[:issues]
    @wiki_pages     = result[:wiki_pages]
    @blobs          = Kaminari.paginate_array(result[:blobs]).page(params[:page]).per(20)
    @total_results = @projects.count + @merge_requests.count + @issues.count + @wiki_pages.count + @blobs.total_count
  end
end
