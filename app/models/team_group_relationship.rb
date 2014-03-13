# == Schema Information
#
# Table name: team_group_relationships
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  group_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeamGroupRelationship < ActiveRecord::Base
  include Watchable
  include RelationTable


  attr_accessible :group_id, :team_id

  belongs_to :group
  belongs_to :team

  validates :group,           presence: true
  validates :team,            presence: true
  validates :team_id, uniqueness: { scope: :group_id }

  relations(:team, :group)

  watch do
    source watchable_name do
      from :create,  to: :created
      from :update,  to: :updated
      from :destroy, to: :deleted
    end
  end

  scope :with_group, ->(group) {where(group_id: group)}

  delegate :name, to: :team, allow_nil: true, prefix: true
end
