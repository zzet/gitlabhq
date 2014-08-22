class SearchService < BaseService
  def global_search
    query = params[:search]

    {
        groups: search_in_groups(query),
        teams: search_in_teams(query),
        users: search_in_users(query),
        projects: search_in_projects(query),
        merge_requests: search_in_merge_requests(query),
        issues: search_in_issues(query),
        repositories: search_in_repository(query),
    }
  end

  def project_search(project)
    query = params[:search]
    {
        groups: {},
        teams: {},
        users: {},
        projects: {},
        merge_requests: search_in_merge_requests(query, project),
        issues: search_in_issues(query, project),
        repositories: search_in_repository(query, project),
    }
  end

  private

  def search_in_projects(query)
    opt = {
      pids: projects_ids,
      order: params[:order],
      fields: %w(name^10 path^9 description^5
             name_with_namespace^2 path_with_namespace),
      highlight: true
    }

    group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
    opt[:namespace_id] = group.id if group

    opt[:category] = params[:category] if params[:category].present?

    begin
      response = Project.search(query, options: opt, page: page)

      categories_list = if query.blank?
                          Project.category_counts.map do |category|
                            { category: category.name, count: category.count }
                          end
                        else
                          response.response["facets"]["categoryFacet"]["terms"].map do |term|
                            { category: term["term"], count: term["count"] }
                          end
                        end

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count,
        namespaces: namespaces(response.response["facets"]["namespaceFacet"]["terms"]),
        categories: categories_list
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_groups(query)
    opt = {
      gids: current_user ? current_user.authorized_groups.ids : [],
      order: params[:order],
      fields: %w(name^10 path^5 description),
      highlight: true
    }

    begin
      response = Group.search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_teams(query)
    opt = {
      tids: current_user ? current_user.known_teams.ids : [],
      order: params[:order],
      fields: %w(name^10 path^5 description),
      highlight: true
    }

    begin
      response = Team.search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_users(query)
    opt = {
      active: true,
      order: params[:order],
      highlight: true
    }

    begin
      response = User.search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_merge_requests(query, project = nil)
    opt = {
      projects_ids: project ? [project.id] : projects_ids,
      order: params[:order],
      highlight: true
    }

    begin
      response = MergeRequest.search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_issues(query, project = nil)
    opt = {
      projects_ids: project ? [project.id] : projects_ids,
      order: params[:order]
    }

    begin
      response = Issue.search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_repository(query, project = nil)
    opt = {
      repository_id: project ? [project.id] : projects_ids,
      highlight: true,
      order: params[:order]
    }

    if params[:language].present? && params[:language] != 'All'
      opt.merge!({ language: params[:language] })
    end

    begin
      res = Repository.search(query, options: opt, page: page)

      project_result_params = Proc.new do |r|
        pr = Project.find_by(id: r["term"])
        if pr
          {
              name: pr.name_with_namespace,
              path: pr.path_with_namespace,
              count: r["count"]
          }
        else
          nil
        end
      end

      res[:blobs][:projects] = res[:blobs][:repositories].
          map(&project_result_params).compact
      res[:commits][:projects] = res[:commits][:repositories].
          map(&project_result_params).compact
      res
    rescue Exception => e
      {}
    end
  end

  def projects_ids
    @allowed_projects_ids ||= begin
      if params[:namespace].present?
        namespace = Namespace.find_by(path: params[:namespace])
        if namespace
          return namespace.projects.where(id: known_projects_ids).pluck(:id)
        end
      end

      known_projects_ids
    end
  end

  def page
    return @current_page if defined?(@current_page)

    @current_page = params[:page].to_i
    @current_page = 1 if @current_page == 0
    @current_page
  end

  def known_projects_ids
    known_projects_ids = []
    known_projects_ids += current_user.known_projects.pluck(:id) if current_user
    known_projects_ids + Project.public_or_internal_only(current_user).pluck(:id)
  end

  def namespaces(terms)
    founded_terms = terms.select { |term| term['count'] > 0 }
    grouped_terms = founded_terms.inject({}) do |memo, term|
      memo[term["term"]] = term["count"]
      memo
    end

    select_hash = Namespace.find(grouped_terms.keys).map do |namespace|
      { namespace: namespace, count: grouped_terms[namespace.id] }
    end
    select_hash.sort { |x, y| y[:count] <=> x[:count] }
  end
end
