# == Schema Information
#
# Table name: team_project_relationships
#
#  id         :integer          not null, primary key
#  project_id :integer
#  team_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeamProjectRelationship < ActiveRecord::Base
  include Watchable

  attr_accessible :project_id, :team_id

  belongs_to :team
  belongs_to :project

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  validates :project,         presence: true
  validates :team,            presence: true

  scope :with_project, ->(project){ where(project_id: project) }

  delegate :name, to: :team, allow_nil: true, prefix: true

  actions_to_watch [:created, :deleted, :updated]
end
