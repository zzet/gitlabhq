module Teams::ProjectsActions
  private

  def assign_on_projects_action(projects)
    unless current_user.admin?
      allowed_project_ids = (current_user.master_projects.pluck(:id) + current_user.created_projects.pluck(:id) + current_user.owned_projects.pluck(:id)).uniq
      projects = projects.where(id: allowed_project_ids)
    end

    projects.each do |project|
      team.team_project_relationships.create(project_id: project.id)
    end

    receive_delayed_notifications
  end

  def resign_from_projects_action(projects)
    tprs = team.team_project_relationships.where(project_id: projects)
    tprs.destroy_all

    receive_delayed_notifications
  end
end
