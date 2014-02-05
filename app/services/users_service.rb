class UsersService < BaseService
  attr_accessor :user, :current_user, :params

  def initialize(current_user, user, params = {})
    @current_user, @user, @params = current_user, user, params.dup
  end

  def block
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

  def delete
    # 1. Remove groups where user is the only owner
    user.solo_owned_groups.map(&:destroy)

    # 2. Remove user with all authored content including personal projects
    user.destroy
    receive_delayed_notifications
  end
end
