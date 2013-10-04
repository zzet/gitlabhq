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

  attr_accessible :group_id, :team_id

  belongs_to :group
  belongs_to :team

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  validates :group,           presence: true
  validates :team,            presence: true

  scope :with_group, ->(group) {where(group_id: group)}

  delegate :name, to: :team, allow_nil: true, prefix: true

  actions_to_watch [:created, :deleted, :updated]
end
