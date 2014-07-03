# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  type        :string(255)
#  description :string(255)      default(""), not null
#  avatar      :string(255)
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Group < Namespace
  include Watchable
  include Favouriteable
  include GroupsSearch

  has_many :team_group_relationships, dependent: :destroy
  has_many :teams,                    through: :team_group_relationships
  has_many :team_user_relationships,  through: :teams
  has_many :admins,                   -> { where({ users: { state: :active },
                                                   team_user_relationships: { team_access: [Gitlab::Access::OWNER, Gitlab::Access::MASTER] } })},
                                      through: :team_user_relationships, source: :user

  has_many :users_groups, dependent: :destroy
  has_many :users,      -> { where({ users: { state: :active } }) }, through: :users_groups

  has_many :guests,     -> { where({ users: { state: :active },
                                     users_groups: { group_access: Gitlab::Access::GUEST } })},
                        through: :users_groups, source: :user

  has_many :reporters,  -> { where({ users: { state: :active },
                                     users_groups: { group_access: Gitlab::Access::REPORTER } })},
                        through: :users_groups, source: :user

  has_many :developers, -> { where({ users: { state: :active },
                                     users_groups: { group_access: Gitlab::Access::DEVELOPER } })},
                        through: :users_groups, source: :user

  has_many :masters,    -> { where({ users: { state: :active },
                                     users_groups: { group_access: [Gitlab::Access::MASTER, Gitlab::Access::OWNER] } })},
                        through: :users_groups, source: :user

  has_many :owners,     -> { where({ users: { state: :active },
                                     users_groups: { group_access: Gitlab::Access::OWNER } })},
                        through: :users_groups, source: :user

  watch do
    source watchable_name do
      title 'Group actions'
      description 'Notify about group update/destroy. Add/delete users. Assign/Reassign users.'
      from :create,   to: :created
      from :update,   to: :updated
      from :destroy,  to: :deleted
      # Mass actions
      from :memberships_add,  to: :members_added
      from :teams_add,        to: :teams_added
      from :teams_remove,     to: :teams_removed
    end

    source :project do
      title 'Project add/delete'
      description 'Notify about project add/delete from group.'
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
      title "Membership's actions"
      description 'Notify about add/delete users from projects.'
      before do: -> { @target = @source.group }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end

    source :team_group_relationship do
      title 'Team assignation/resignation'
      description 'Notify about team assignation/resignation from group.'
      before do: -> { @target = @source.group }
      from :create,   to: :assigned
      from :destroy,  to: :resigned
    end
  end

  scope :without_team, ->(team) { team.groups.present? ? where.not(id: team.groups) : all }

  attr_accessible :avatar

  validate :avatar_type, if: ->(user) { user.avatar_changed? }
  validates :avatar, file_size: { maximum: 100.kilobytes.to_i }

  mount_uploader :avatar, AttachmentUploader

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

  def has_master?(user)
    members.masters.where(user_id: user).any?
  end

  def last_owner?(user)
    owners.include?(user) && owners.size == 1
  end

  def members
    users_groups
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def public_profile?
    projects.public_only.any?
  end
end
