# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
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
  has_many :admins,                   through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: [Gitlab::Access::OWNER, Gitlab::Access::MASTER] } }

  has_many :users_groups, dependent: :destroy
  has_many :users,      through: :users_groups, conditions: { users: { state: :active } }
  has_many :guests,     through: :users_groups, source: :user, conditions: { users: { state: :active }, users_groups: { group_access: Gitlab::Access::GUEST } }
  has_many :reporters,  through: :users_groups, source: :user, conditions: { users: { state: :active }, users_groups: { group_access: Gitlab::Access::REPORTER } }
  has_many :developers, through: :users_groups, source: :user, conditions: { users: { state: :active }, users_groups: { group_access: Gitlab::Access::DEVELOPER } }
  has_many :masters,    through: :users_groups, source: :user, conditions: { users: { state: :active }, users_groups: { group_access: [Gitlab::Access::MASTER, Gitlab::Access::OWNER] } }

  watch do
    source watchable_name do
      from :create,   to: :created
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :project do
      before do: -> { @target = @source.group }, conditions: -> { @source.group.present? }
      from :create,   to: :added,   conditions: -> { @source.group.present? }
      from :update,   to: :added,   conditions: -> { @source.group.present? && @source.namespace_id_changed? && @source.namespace_id != @changes["namespace_id"].first }
      from :update,   to: :removed, conditions: -> { @source.namespace_id_changed? && @source.namespace_id != @changes["namespace_id"].first && Group.find_by_id(@changes["namespace_id"].first).present? } do
        @target = Group.find_by_id(@changes["namespace_id"].first)
        @event_data[:owner_changes] = @changes
      end
      from :destroy,  to: :deleted, conditions: -> { @source.group.present? }
    end

    source :users_group do
      before do: -> { @target = @source.group }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end

    source :team_group_relationship do
      before do: -> { @target = @source.group }
      from :create,   to: :assigned
      from :destroy,  to: :resigned
    end
  end

  scope :without_team, ->(team) { team.groups.present? ? where("namespaces.id NOT IN (:ids)", ids: team.groups.pluck(:id)) : scoped }

  def human_name
    name
  end

  def owners
    @owners ||= users_groups.owners.map(&:user)
  end

  def add_users(user_ids, group_access)
    user_ids.compact.each do |user_id|
      user = self.users_groups.find_or_initialize_by(user_id: user_id)
      user.update_attributes(group_access: group_access)
    end
  end

  def add_user(user, group_access)
    self.users_groups.create(user_id: user.id, group_access: group_access)
  end

  def add_owner(user)
    self.add_user(user, UsersGroup::OWNER)
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

  def has_owner?(user)
    owners.include?(user) || admins.include?(user) || masters.include?(user)
  end

  def last_owner?(user)
    owners.include?(user) && owners.size == 1
  end

  def members
    users_groups
  end
end
