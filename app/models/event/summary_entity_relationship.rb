# == Schema Information
#
# Table name: event_summary_entity_relationships
#
#  id          :integer          not null, primary key
#  summary_id  :integer
#  entity_id   :integer
#  entity_type :string(255)
#  options     :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Event::SummaryEntityRelationship < ActiveRecord::Base

  attr_accessible :summary_id, :entity_id, :entity_type, :options

  belongs_to :summary
  belongs_to :entity, polymorphic: true

  validates :summary, presence: true
  validates :entity,  presence: true
  validates :entity_id, uniqueness: { scope: [:entity_type, :summary_id] }
end
