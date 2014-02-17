class UsersService < BaseService
  attr_accessor :user, :current_user, :params

  def initialize(current_user, user, params = {})
    @current_user, @user, @params = current_user, user, params.dup
  end

  def block
    projects_ids = (user.projects.ids +
                    personal_projects.ids +
                    user.groups.projects.ids +
                    user.teams.projects.ids).uniq
    teams_ids = user.teams.ids

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

    Project.where(id: projects_ids).find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end

    Team.where(id: teams_ids).find_each do |team|
      Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)
    end

    receive_delayed_notifications
  end

  def delete
    projects_ids = (user.projects.ids +
                    personal_projects.ids +
                    user.solo_owned_groups.projects.ids +
                    user.teams.projects.ids).uniq

    teams_ids = user.teams.ids

    # 1. Remove groups where user is the only owner
    user.solo_owned_groups.map(&:destroy)

    # 2. Remove user with all authored content including personal projects
    user.destroy

    Project.where(id: projects_ids).find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end

    Team.where(id: teams_ids).find_each do |team|
      Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)
    end

    receive_delayed_notifications
  end
end
