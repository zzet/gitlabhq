class SearchService < BaseService
  def global_search
    query = params[:search]
    # fix bug with search russian text
    #query = Shellwords.shellescape(query) if query.present?

    return global_search_result unless query.present?

    known_projects_ids = projects_ids(params)
    search_options = { pids: known_projects_ids, order: params[:order] }

    group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
    search_options[:namespace_id] = group.id if group

    page = params[:page].to_i
    page = 1 if page == 0

    global_search_result[:groups]         = Group.search(query, options: search_options.merge({in: %w(name^10 path^5 description)}), page: page)
    global_search_result[:teams]          = Team.search(query, options: search_options.merge({in: %w(name^10 path^5 description)}), page: page)
    global_search_result[:users]          = User.search(query, options: search_options, page: page)
    global_search_result[:projects]       = Project.search(query, options: search_options.merge({in: %w(name^10 path^9 description^5 name_with_namespace^2 path_with_namespace)}), page: page)
    global_search_result[:merge_requests] = MergeRequest.search(query, options: { projects_ids: known_projects_ids, page: page })
    global_search_result[:issues]         = Issue.search(query, options: { projects_ids: known_projects_ids, page: page })

    repository_search_options = search_options.merge({ repository_id: known_projects_ids, highlight: true })
    repository_search_options.merge!({ language: params[:language] }) if params[:language].present? && params[:language] != "All"

    global_search_result[:repositories]   = Repository.search(query, options: repository_search_options, page: page)

    # temp disabled
    #global_search_result[:total_results]  = %w(groups teams users projects issues merge_requests).sum { |items| global_search_result[items.to_sym].size }

    global_search_result
  end

  private

  def projects_ids(params)
    if params[:project_id].present?
      project = Project.find_by(id: params[:project_id])
      if current_user.can?(:read_project, project)
        [project.id]
      else
        known_projects_ids(params)
      end
    else
      known_projects_ids(params)
    end
  end

  def known_projects_ids(params)
    known_projects_ids = []
    known_projects_ids += current_user.known_projects.pluck(:id) if current_user
    known_projects_ids += Project.public_or_internal_only(current_user).pluck(:id)
  end

  def global_search_result
    @result ||= {
      groups: [],
      teams: [],
      users: [],
      projects: [],
      merge_requests: [],
      issues: [],
      repositories: [],
      total_results: 0,
    }
  end
end
