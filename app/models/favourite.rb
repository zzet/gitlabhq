class Favourite < ActiveRecord::Base

  attr_accessible :entity, :entity_id, :entity_type, :user_id

  belongs_to :user
  belongs_to :entity, polymorphic: true

  validates :user, presence: true
  validates :entity, presence: true
  validates :user_id, uniqueness: { scope: [:entity_type, :entity_id]}
end
