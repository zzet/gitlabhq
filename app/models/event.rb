class Event < ActiveRecord::Base
  attr_accessible :action, :data, :target_id, :target_type, :author_id

  belongs_to :author
  belongs_to :target, polymorphic: true

  has_many :notifications,  dependent: :destroy
  has_many :subscriptions,  through: :notifications
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :target,  presence: true
end
