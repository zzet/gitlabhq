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
  include RelationTable


  attr_accessible :team_access, :user_id, :team_id

  belongs_to :team
  belongs_to :user

  validates :team,        presence: true
  validates :user,        presence: true
  validates :user_id,     uniqueness: { scope: [:team_id], message: "already exists in team" }
  validates :team_access, presence: true, inclusion: { in: Gitlab::Access.values_with_owner }

  relations(:team, :user)

  watch do
    source watchable_name do
      from :create,  to: :created
      from :update,  to: :updated
      from :destroy, to: :deleted
    end
  end

  scope :guests,      -> { where(team_access: GUEST) }
  scope :reporters,   -> { where(team_access: REPORTER) }
  scope :developers,  -> { where(team_access: DEVELOPER) }
  scope :masters,     -> { where(team_access: MASTER) }
  scope :owners,      -> { where(team_access: OWNER) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  delegate :name, to: :team, allow_nil: true, prefix: true

  def access_field
    team_access
  end
end
