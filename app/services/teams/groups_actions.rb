module Teams::GroupsActions
  private

  def assign_on_groups_action(groups = nil)
    unless current_user.admin?
      allowed_group_ids = (current_user.created_groups.pluck(:id) + current_user.owned_groups.pluck(:id)).uniq
      groups = groups.where(id: allowed_group_ids)
    end

    multiple_action("groups_add", "team", team, groups) do
      groups.each do |group|
        team.team_group_relationships.create(group_id: group.id)
      end
    end

    Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)

    groups.find_each do |group|
      Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)

      group.projects.find_each do |project|
        Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
      end
    end
  end

  def resign_from_groups_action(groups)
    tgrs = team.team_group_relationships.where(group_id: groups)

    group = tgrs.group
    projects = group.projects

    tgrs.destroy_all

    Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)

    projects.find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end

    receive_delayed_notifications
  end
end
