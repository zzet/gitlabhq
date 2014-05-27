module SearchHelper

  def search_path_with_project(type, params, options = {})
    options.merge!(type: type, search: params[:search], project: params[:project])
    search_path(options)
  end

  def search_autocomplete_opts(term, project = nil)
    return unless current_user

    if project
      file_names_autocomplete(term, project)
    else
      groups_autocomplete(term) + teams_autocomplete(term) + projects_autocomplete(term)
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
    Project.search(term, options: { pids: current_user.known_projects.pluck(:id), non_archived: true }, per: limit).records.map do |p|
      {
        label: "project: #{search_result_sanitize(p.name_with_namespace)}",
        url: project_path(p)
      }
    end
  end

  def file_names_autocomplete(term, project, limit = 5)
    Repository.search_file_names(term, per: limit).results.map do |file_name|
      {
        label: file_name.fields['blob.path'],
        url: project_blob_path(project, ['master', file_name.fields['blob.path']].join('/'))
      }
    end
  end

  def search_result_sanitize(str)
    Sanitize.clean(str)
  end
end
