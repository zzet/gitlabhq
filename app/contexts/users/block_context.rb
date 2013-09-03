module Users
  class BlockContext < Users::BaseContext
    def execute
      User.transaction do
        if user.block
          # Remove user from all teams
          user.user_teams.find_each do |team|
            Gitlab::UserTeamManager.remove_member_from_team(team, user)
          end

          # Remove user from all groups
          user.users_groups.find_each do |membership|
            # skip owned resources
            next if membership.group.owners.include?(user)

            return false unless membership.destroy
          end

          # Remove user from all projects and
          user.users_projects.find_each do |membership|
            # skip owned resources
            next if membership.project.owner == user

            return false unless membership.destroy
          end

        end
      end

      receive_delayed_notifications
    end
  end
end
