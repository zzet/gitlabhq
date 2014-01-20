class SearchService < BaseService
  def global_search
    query = params[:search]
    query = Shellwords.shellescape(query) if query.present?
    return global_search_result unless query.present?

    authorized_projects_ids = []
    authorized_projects_ids += current_user.authorized_projects.pluck(:id) if current_user
    authorized_projects_ids += Project.public_or_internal_only(current_user).pluck(:id)

    group = Group.find_by_id(params[:group_id]) if params[:group_id].present?
    projects = Project.where(id: authorized_projects_ids)
    projects = projects.where(namespace_id: group.id) if group
    projects = projects.search(query)
    project_ids = projects.pluck(:id)

    global_search_result[:projects] = projects.limit(20)
    global_search_result[:merge_requests] = MergeRequest.in_projects(project_ids).search(query).order('updated_at DESC').limit(20)
    global_search_result[:issues] = Issue.where(project_id: project_ids).search(query).order('updated_at DESC').limit(20)
    global_search_result[:total_results] = %w(projects issues merge_requests).sum { |items| global_search_result[items.to_sym].size }

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
      project_search_result[:merge_requests] = project.merge_requests.search(query).order('updated_at DESC').limit(20)
      project_search_result[:issues] = project.issues.search(query).order('updated_at DESC').limit(20)
      project_search_result[:total_results] = %w(issues merge_requests).sum { |items| project_search_result[items.to_sym].size }
    end

    project_search_result
  end

  private

  def global_search_result
    @result ||= {
      projects: [],
      merge_requests: [],
      issues: [],
      total_results: 0,
    }
  end

  def project_search_result
    @result ||= {
      merge_requests: [],
      issues: [],
      blobs: [],
      total_results: 0,
    }
  end
end
