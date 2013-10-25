class SearchContext < BaseContext
  attr_accessor :current_user, :params

  def initialize(user, params)
    @current_user, @params = user, params.dup
  end

  def execute
    project_id = params[:project_id]
    group_id = params[:group_id]
    team_id = params[:team_id]

    projects = current_user.known_projects

    if projects.any?
      if group_id.present?
        @group = Group.find(group_id)
        projects = @group.projects.where(id: projects)
      elsif team_id.present?
        @team = Team.find(team_id)
        projects = (@team.projects.where(id: projects) + @team.groups_projects.where(id: projects)).uniq
      elsif project_id.present?
        @project = Project.find(project_id)
        projects = projects.where(id: @project)
      end
    end

    query = params[:search]

    return result unless query.present?

    result[:projects] = projects.search(query)

    # Search inside single project
    project = projects.first if projects.length == 1

    if params[:search_code].present?
      result[:blobs] = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
    else
      result[:merge_requests] = MergeRequest.in_projects(projects).search(query).order('updated_at DESC').limit(20)
      result[:issues]         = Issue.where(project_id: projects).search(query).order('updated_at DESC').limit(20)
      result[:wiki_pages] = []
    end

    result
  end

  def result
    @result ||= {
      projects: [],
      merge_requests: [],
      issues: [],
      wiki_pages: [],
      blobs: []
    }
  end
end
