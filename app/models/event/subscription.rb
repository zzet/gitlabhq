class Event::Subscription < ActiveRecord::Base
  include Actionable

  attr_accessible :action, :last_notified_at, :notification_interval, :target_id, :target_type, :user_id

  # Relations
  belongs_to :user
  belongs_to :target, polymorphic: true
  has_many :notifications, dependent: :destroy

  # Validations
  validates :user, presence: true
  validates :target, presence: true

  # Scopes
  scope :on_event, ->(event) { where(action: event.action, target_id: event.target_id, target_type: event.target_type) }

end
