class UsersService < BaseService
  attr_accessor :user, :current_user, :params

  def initialize(current_user, user, params = {})
    @current_user, @user, @params = current_user, user, params.dup
  end

  def block
    projects_ids = (user.projects.pluck(:id) +
                    user.personal_projects.pluck(:id) +
                    Project.where(namespace_id: user.groups.pluck(:id)).pluck(:id) +
                    TeamProjectRelationship.where(team_id: user.teams.pluck(:id)).pluck(:project_id)).uniq
    teams_ids = user.teams.pluck(:id)

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

    projects_ids.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end

    teams_ids.each do |team_id|
      reindex_with_elastic(Team, team_id)
    end

    receive_delayed_notifications
  end

  def delete
    projects_ids = (user.projects.pluck(:id) +
                    user.personal_projects.pluck(:id) +
                    Project.where(namespace_id: user.groups.pluck(:id)).pluck(:id) +
                    TeamProjectRelationship.where(team_id: user.teams.pluck(:id)).pluck(:project_id)).uniq
    teams_ids = user.teams.pluck(:id)

    # 1. Remove groups where user is the only owner
    user.solo_owned_groups.map(&:destroy)

    # 2. Remove user with all authored content including personal projects
    user.destroy

    projects_ids.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end

    teams_ids.each do |team_id|
      reindex_with_elastic(Team, team_id)
    end

    receive_delayed_notifications
  end
end
