module Teams::UsersActions
  private

  def add_memberships_action(users, access)
    action = Gitlab::Event::SyntheticActions::MEMBERSHIPS_ADD
    multiple_action(action, "team", team, users) do
      team.add_users(users, access)
    end

    team_projects_ids.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end
  end

  def remove_membership_action(user)
    team.remove_user(user)

    team_projects_ids.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end

    receive_delayed_notifications
  end

  def update_memberships_action(members, access)
    member = team.team_user_relationships.find_by(user_id: members)
    result = member.update(team_access: access)

    receive_delayed_notifications

    project_ids = team.projects.pluck(:id) + team.accessed_projects.pluck(:id)

    project_ids.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end

    result
  end

  private

  def team_projects_ids
    team.projects.pluck(:id) + team.accessed_projects.pluck(:id)
  end
end
