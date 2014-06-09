class ProjectsFinder
  def execute(current_user, options = {})
    group = options[:group]

    projects = all_projects(current_user)
    projects = projects.where(namespace_id: group.id) if group.present?
    projects
  end

  private

  def all_projects(user)
    if user
      user.admin? ? Project.all : user.known_projects
    else
      Project.public_only
    end
  end
end
