module Teams::GroupsActions
  private

  def assign_on_groups_action(groups = nil)
    unless current_user.admin?
      allowed_group_ids = (current_user.created_groups.select("namespaces.id") + current_user.owned_groups.select("namespaces.id")).uniq
      groups = groups.where(id: allowed_group_ids)
    end

    multiple_action("groups_add", "team", team, groups) do
      groups.each do |group|
        team.team_group_relationships.create(group_id: group.id)
      end
    end

    reindex_with_elastic(Team, team.id)

    projects = Project.where(namespace_id: groups.pluck(:id)).pluck(:id)

    projects.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end
  end

  def resign_from_groups_action(groups)
    tgrs = team.team_group_relationships.where(group_id: groups)

    projects = Project.where(namespace_id: groups).pluck(:id)

    tgrs.destroy_all

    projects.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end

    receive_delayed_notifications
  end
end
