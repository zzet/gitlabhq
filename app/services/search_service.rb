class SearchService < BaseService
  def global_search
    query = params[:search]
    query = Shellwords.shellescape(query) if query.present?

    return global_search_result unless query.present?

    known_projects_ids = []
    known_projects_ids += current_user.known_projects.pluck(:id) if current_user
    known_projects_ids += Project.public_or_internal_only(current_user).pluck(:id)

    group = Group.find_by_id(params[:group_id]) if params[:group_id].present?

    search_options = { pids: known_projects_ids }
    search_options[:namespace_id] = group.id if group

    global_search_result[:groups]         = Group.search(query, options: search_options, page: params[:page])
    global_search_result[:teams]          = Team.search(query, options: search_options, page: params[:page])
    global_search_result[:users]          = User.search(query, options: search_options, page: params[:page])
    global_search_result[:projects]       = Project.search(query, options: search_options, page: params[:page])
    global_search_result[:merge_requests] = MergeRequest.search(query, options: { projects_ids: known_projects_ids, page: params[:page] })
    global_search_result[:issues]         = Issue.search(query, options: { projects_ids: known_projects_ids, page: params[:page] })
    global_search_result[:repositories]   = Repository.search(query, options: search_options, page: params[:page])

    global_search_result[:total_results]  = %w(projects issues merge_requests).sum { |items| global_search_result[items.to_sym].size }

    global_search_result
  end

  def project_search(project)
    query = params[:search]
    query = Shellwords.shellescape(query) if query.present?
    return project_search_result unless query.present?

    if params[:search_code].present?
      blobs = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
      blobs = Kaminari.paginate_array(blobs).page(params[:page]).per(20)
      project_search_result[:blobs] = blobs
      project_search_result[:total_results] = blobs.total_count
    else
      project_search_result[:merge_requests]  = MergeRequest.search(query, options: { projects_ids: [project.id], page: params[:page]})
      project_search_result[:issues]          = Issue.search(query, options: { projects_ids: [project.id], page: params[:page]})
      project_search_result[:total_results]   = %w(issues merge_requests).sum { |items| project_search_result[items.to_sym].size }
    end

    project_search_result
  end

  private

  def global_search_result
    @result ||= {
      groups: [],
      teams: [],
      users: [],
      projects: [],
      merge_requests: [],
      issues: [],
      code: [],
      total_results: 0,
    }
  end

  def project_search_result
    @result ||= {
      merge_requests: [],
      issues: [],
      blobs: [],
      commits: [],
      total_results: 0,
    }
  end
end