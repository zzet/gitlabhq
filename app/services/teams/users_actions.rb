module Teams::UsersActions
  private

  def add_memberships_action(users, access)
    multiple_action("memberships_add", "team", team, users) do
      team.add_users(users, access)
    end

    project_ids = team.projects.ids + team.accessed_projects.ids

    project_ids.each do |project_id|
      Elastic::BaseIndexer.perform_async(:update, Project.name, project_id)
    end
  end

  def remove_membership_action(user)
    team.remove_user(user)

    project_ids = team.projects.ids + team.accessed_projects.ids

    project_ids.each do |project_id|
      Elastic::BaseIndexer.perform_async(:update, Project.name, project_id)
    end

    receive_delayed_notifications
  end

  def update_memberships_action(members, access)
    member = team.team_user_relationships.find_by(user_id: members)
    result = member.update(team_access: access)

    receive_delayed_notifications

    project_ids = team.projects.ids + team.accessed_projects.ids

    project_ids.each do |project_id|
      Elastic::BaseIndexer.perform_async(:update, Project.name, project_id)
    end

    result
  end
end
