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

  has_many :user_team_group_relationships, dependent: :destroy
  has_many :user_teams, through: :user_team_group_relationships
  has_many :admins, through: :user_teams, class_name: User, conditions: { user_team_user_relationships: { group_admin: true } }

  has_many :users_groups, dependent: :destroy
  has_many :users, through: :users_groups

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  actions_to_watch [:created, :deleted, :updated, :transfer]
  after_create :add_owner

  def human_name
    name
  end

  def owners
    @owners ||= (users_groups.owners.map(&:user) << owner).uniq
  end

  def add_users(user_ids, group_access)
    user_ids.compact.each do |user_id|
      self.users_groups.create(user_id: user_id, group_access: group_access)
    end
  end

  def change_owner(user)
    self.owner = user
    membership = users_groups.where(user_id: user.id).first

    if membership
      membership.update_attributes(group_access: UsersGroup::OWNER)
    else
      add_owner
    end
  end

  private

  def add_owner
    self.add_users([owner.id], UsersGroup::OWNER)
  end
end
