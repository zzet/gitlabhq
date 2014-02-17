module Teams::UsersActions
  private

  def add_memberships_action(users, access)
    multiple_action("memberships_add", "team", team, users) do
      team.add_users(users, access)
    end

    team.members.where(id: users).find_each do |user|
      Elastic::BaseIndexer.perform_async(:update, user.class.name, user.id)
    end

    project_ids = team.projects.ids + team.accessed_projects.ids

    Project.where(id: project_ids).find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end
  end

  def remove_membership_action(user)
    team.remove_user(user)

    Elastic::BaseIndexer.perform_async(:update, user.class.name, user.id)

    project_ids = team.projects.ids + team.accessed_projects.ids

    Project.where(id: project_ids).find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end

    receive_delayed_notifications
  end

  def update_memberships_action(members, access)
    member = team.team_user_relationships.find_by(user_id: members)
    result = member.update(team_access: access)

    receive_delayed_notifications

    team.members.where(id: users).find_each do |user|
      Elastic::BaseIndexer.perform_async(:update, user.class.name, user.id)
    end

    project_ids = team.projects.ids + team.accessed_projects.ids

    Project.where(id: project_ids).find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end

    result
  end
end
