module Users
  class BlockContext < Users::BaseContext
    def execute
      User.transaction do
        if user.block
          user.team_user_relationships.find_each do |membership|
            # skip owned resources
            next if membership.team.owners.include?(user)

            return false unless membership.destroy
          end

          user.users_groups.find_each do |membership|
            # skip owned resources
            next if membership.group.owners.include?(user)

            return false unless membership.destroy
          end

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
