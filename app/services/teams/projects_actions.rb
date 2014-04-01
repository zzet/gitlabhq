module Teams::ProjectsActions
  private

  def assign_on_projects_action(projects)
    unless current_user.admin?
      allowed_project_ids = (current_user.master_projects.pluck(:id) + current_user.created_projects.pluck(:id) + current_user.owned_projects.pluck(:id)).uniq
      projects = projects.where(id: allowed_project_ids)
    end

    multiple_action("projects_add", "team", team, projects) do
      projects.each do |project|
        team.team_project_relationships.create(project_id: project.id)
        begin
          Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
        rescue
        end
      end
    end
  end

  def resign_from_projects_action(projects)
    tprs = team.team_project_relationships.where(project_id: projects)
    tprs.destroy_all

    Project.where(id: projects).find_each do |project|
      begin
        Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
      rescue
      end
    end

    receive_delayed_notifications
  end
end
