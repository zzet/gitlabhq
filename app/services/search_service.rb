class SearchService < BaseService
  def global_search
    query = params[:search]
    # fix bug with search russian text
    #query = Shellwords.shellescape(query) if query.present?

    #return global_search_result unless query.present?

    global_search_result[:groups]         = search_in_groups(query)
    global_search_result[:teams]          = search_in_teams(query)
    global_search_result[:users]          = search_in_users(query)
    global_search_result[:projects]       = search_in_projects(query)
    global_search_result[:merge_requests] = search_in_merge_requests(query)
    global_search_result[:issues]         = search_in_issues(query)
    global_search_result[:repositories]   = search_in_repository(query)

    # temp disabled
    #global_search_result[:total_results]  = %w(groups teams users projects issues merge_requests).sum { |items| global_search_result[items.to_sym].size }

    global_search_result
  end

  private

  def search_in_projects(query)
    opt = {
      pids: projects_ids,
      order: params[:order],
      fields: %w(name^10 path^9 description^5
             name_with_namespace^2 path_with_namespace),
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
        namespaces: response.response["facets"]["namespaceFacet"]["terms"].map {|term| { namespace: Namespace.find(term["term"]), count: term["count"] } },
        categories: categories_list
      }
    rescue Exception => e
      []
    end
  end

  def search_in_groups(query)
    opt = {
      gids: current_user.authorized_groups.ids,
      order: params[:order],
      fields: %w(name^10 path^5 description),
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
      []
    end
  end

  def search_in_teams(query)
    opt = {
      tids: current_user.known_teams.ids,
      order: params[:order],
      fields: %w(name^10 path^5 description),
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
      []
    end
  end

  def search_in_users(query)
    opt = {
      active: true,
      order: params[:order]
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
      []
    end
  end

  def search_in_merge_requests(query)
    opt = {
      projects_ids: projects_ids,
      order: params[:order]
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
      []
    end
  end

  def search_in_issues(query)
    opt = {
      projects_ids: projects_ids,
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
      []
    end
  end

  def search_in_repository(query)
    opt = {
      repository_id: projects_ids,
      highlight: true,
      order: params[:order]
    }
    opt.merge!({ language: params[:language] }) if params[:language].present? && params[:language] != "All"

    begin
      res = Repository.search(query, options: opt, page: page)
      res[:blobs][:projects]    = res[:blobs][:repositories].map   { |r| pr = Project.find(r["term"]); { name: pr.name_with_namespace, path: pr.path_with_namespace, count: r["count"] } }
      res[:commits][:projects]  = res[:commits][:repositories].map { |r| pr = Project.find(r["term"]); { name: pr.name_with_namespace, path: pr.path_with_namespace, count: r["count"] } }
      res
    rescue Exception => e
      []
    end
  end

  def projects_ids
    return @allowed_projects_ids if defined?(@allowed_projects_ids)

    @allowed_projects_ids = begin
                              project = begin
                                          if params[:project_id].present?
                                            Project.find_by(id: params[:project_id])
                                          elsif params[:project].present?
                                            Project.find_with_namespace(params[:project])
                                          end
                                        end

                              namespace = begin
                                            if params[:namespace].present?
                                              Namespace.find_by(path: params[:namespace])
                                            end
                                          end
                              if project
                                if current_user.can?(:read_project, project)
                                  [project.id]
                                else
                                  known_projects_ids
                                end
                              elsif namespace
                                namespace.projects.map { |pr| pr.id if known_projects_ids.include?(pr.id) }
                              else
                                known_projects_ids
                              end
                            rescue Exception => e
                              []
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
