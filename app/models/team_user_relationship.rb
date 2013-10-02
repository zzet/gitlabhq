# == Schema Information
#
# Table name: team_user_relationships
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  team_id     :integer
#  team_access :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class TeamUserRelationship < ActiveRecord::Base
  include Gitlab::Access
  include Watchable

  attr_accessible :team_access, :user_id, :team_id

  belongs_to :team
  belongs_to :user

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  scope :guests,      -> { where(team_access: GUEST) }
  scope :reporters,   -> { where(team_access: REPORTER) }
  scope :developers,  -> { where(team_access: DEVELOPER) }
  scope :masters,     -> { where(team_access: MASTER) }
  scope :owners,      -> { where(team_access: OWNER) }

  scope :with_user, ->(user) { where(user_id: user.id) }

  validates :team,        presence: true
  validates :user,        presence: true
  validates :user_id,     uniqueness: { scope: [:team_id], message: "already exists in team" }
  validates :team_access, presence: true, inclusion: { in: Gitlab::Access.values_with_owner }

  delegate :name, to: :team, allow_nil: true, prefix: true

  actions_to_watch [:created, :updated, :deleted]

  def access_field
    team_access
  end
end
