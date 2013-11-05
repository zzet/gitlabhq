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
        projects = projects.where(id: (@team.projects.pluck(:id) + @team.groups_projects.pluck(:id)).uniq)
      elsif project_id.present?
        @project = Project.find(project_id)
        projects = projects.where(id: @project)
      end
    end

    query = params[:search]
    query = Shellwords.shellescape(query) if query.present?

    return result unless query.present?

    result[:project] = projects.first if project_id.present?
    result[:projects] = projects.search(query)
    result[:projects] = Project.where("projects.id in (?) OR projects.public = true", project_ids).search(query).limit(20)

    # Search inside single project
    single_project_search(Project.where(id: project_ids), query)
    result
  end

  def single_project_search(projects, query)
    project = projects.first if projects.length == 1

    if params[:search_code].present?
      result[:blobs] = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
    else
      result[:merge_requests] = MergeRequest.in_projects(projects).search(query).order('updated_at DESC').limit(20)
      result[:issues]         = Issue.where(project_id: projects).search(query).order('updated_at DESC').limit(20)
      result[:wiki_pages] = []
    end
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
