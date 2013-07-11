module Users
  class BlockContext < Users::BaseContext
    def execute
      User.transaction do
        user.block

        # Remove user from all teams
        user.user_teams.find_each do |team|
          Gitlab::UserTeamManager.remove_member_from_team(team, user)
        end

        UsersProject.with_user(user).destroy_all
      end

      receive_delayed_notifications
    end
  end
end
