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

  has_many :team_group_relationships, dependent: :destroy
  has_many :teams,                    through: :team_group_relationships
  has_many :team_user_relationships,  through: :teams
  has_many :admins,                   through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: [Team::OWNER, Team::MASTER] } }

  has_many :users_groups, dependent: :destroy
  has_many :users, through: :users_groups, conditions: { users: { state: :active } }

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  actions_to_watch [:created, :deleted, :updated, :transfer]

  scope :without_team, ->(team) { team.groups.present? ? where("namespaces.id NOT IN (:ids)", ids: team.groups.pluck(:id)) : scoped }

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

  def human_access_for entity
    begin
      case entity
      when User
        users_groups.find_by_user_id(entity).human_access
      else
        "None"
      end
    rescue
      "None"
    end
  end

  private

  def add_owner
    self.add_users([owner.id], UsersGroup::OWNER)
  end
end
