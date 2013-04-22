# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string(255)
#  description :string(255)      default(""), not null
#

class Group < Namespace
  include Watchable

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, depended: :destroy, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  actions_to_watch [:created, :deleted, :updated, :transfer]

  def add_users_to_project_teams(user_ids, project_access)
    UsersProject.add_users_into_projects(
      projects.map(&:id),
      user_ids,
      project_access
    )
  end

  def users
    users = User.joins(:users_projects).where(users_projects: {project_id: project_ids})
    users = users << owner
    users.uniq
  end

  def human_name
    name
  end

  def truncate_teams
    UsersProject.truncate_teams(project_ids)
  end

end
