module Teams::UsersActions
  private

  def add_memberships_action(users, access)
    multiple_action("memberships_add", "team", team, users) do
      team.add_users(users, access)
    end
  end

  def remove_membership_action(user)
    team.remove_user(user)

    receive_delayed_notifications
  end

  def update_memberships_action(members, access)
    member = team.team_user_relationships.find_by(user_id: members)
    result = member.update(team_access: access)

    receive_delayed_notifications

    result
  end
end
