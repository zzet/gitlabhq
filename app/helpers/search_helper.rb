module SearchHelper
  def search_autocomplete_opts(term)
    return unless current_user

    resources_results = [
      groups_autocomplete(term),
      teams_autocomplete(term),
      projects_autocomplete(term)
    ].flatten

    generic_results = project_autocomplete + default_autocomplete + help_autocomplete
    generic_results.select! { |result| result[:label] =~ Regexp.new(term, "i") }

    [
      resources_results,
      generic_results
    ].flatten.uniq do |item|
      item[:label]
    end
  end

  def search_filter_path(query, type: :project, order: :created_at)
    case type.to_sym
    when :project
      search_path(type: :project, search: query, order: order)
    when :group
      search_path(type: :group, search: query, order: order)
    when :team
      search_path(type: :team, search: query, order: order)
    when :user
      search_path(type: :user, search: query, order: order)
    when :merge_request
      search_path(type: :merge_request, search: query, order: order)
    when :issue
      search_path(type: :issue, search: query, order: order)
    when :code
      search_path(type: :code, search: query, order: order)
    when :commit
      search_path(type: :commit, search: query, order: order)
    end
  end

  private

  # Autocomplete results for various settings pages
  def default_autocomplete
    [
      { label: "My Profile settings", url: profile_path },
      { label: "My SSH Keys",         url: profile_keys_path },
      { label: "My Dashboard",        url: root_path },
      { label: "Admin Section",       url: admin_root_path },
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { label: "help: API Help",           url: help_page_path("api", "README") },
      { label: "help: Markdown Help",      url: help_page_path("markdown", "markdown") },
      { label: "help: Permissions Help",   url: help_page_path("permissions", "permissions") },
      { label: "help: Public Access Help", url: help_page_path("public_access", "public_access") },
      { label: "help: Rake Tasks Help",    url: help_page_path("raketasks", "README") },
      { label: "help: SSH Keys Help",      url: help_page_path("ssh", "README") },
      { label: "help: System Hooks Help",  url: help_page_path("system_hooks", "system_hooks") },
      { label: "help: Web Hooks Help",     url: help_page_path("web_hooks", "web_hooks") },
      { label: "help: Workflow Help",      url: help_page_path("workflow", "README") },
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      prefix = search_result_sanitize(@project.name_with_namespace)
      ref    = @ref || @project.repository.root_ref

      [
        { label: "#{prefix} - Files",          url: project_tree_path(@project, ref) },
        { label: "#{prefix} - Commits",        url: project_commits_path(@project, ref) },
        { label: "#{prefix} - Network",        url: project_network_path(@project, ref) },
        { label: "#{prefix} - Graph",          url: project_graph_path(@project, ref) },
        { label: "#{prefix} - Issues",         url: project_issues_path(@project) },
        { label: "#{prefix} - Merge Requests", url: project_merge_requests_path(@project) },
        { label: "#{prefix} - Milestones",     url: project_milestones_path(@project) },
        { label: "#{prefix} - Snippets",       url: project_snippets_path(@project) },
        { label: "#{prefix} - Team",           url: project_team_index_path(@project) },
        { label: "#{prefix} - Wall",           url: project_wall_path(@project) },
        { label: "#{prefix} - Wiki",           url: project_wikis_path(@project) },
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  def groups_autocomplete(term, limit = 10)
    Group.search(term, options: { gids: current_user.authorized_groups.pluck(:id)}, per: limit).records.map do |group|
      {
        label: "group: #{search_result_sanitize(group.name)}",
        url: group_path(group)
      }
    end
  end

  # Autocomplete results for the current user's groups
  def teams_autocomplete(term, limit = 10)
    Team.search(term, options: { tids: current_user.known_teams.pluck(:id)}, per: limit).records.map do |team|
      {
        label: "team: #{search_result_sanitize(team.name)}",
        url: team_path(team)
      }
    end
  end

  # Autocomplete results for the current user's projects
  def projects_autocomplete(term, limit = 10)
      Project.search(term,
                     options: {
                      pids: current_user.known_projects.pluck(:id),
                      non_archived: true
                    },
                    per: limit).records.map do |p|
      {
        label: "project: #{search_result_sanitize(p.name_with_namespace)}",
        url: project_path(p)
      }
    end
  end

  def search_result_sanitize(str)
    Sanitize.clean(str)
  end
end
