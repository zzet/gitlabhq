class Event < ActiveRecord::Base
  include Actionable

  attr_accessible :action, :data,
                  :source_id, :source_type, :source,
                  :target_id, :target_type, :target,
                  :author_id, :author


  belongs_to :author, class_name: User
  belongs_to :target, polymorphic: true
  belongs_to :source, polymorphic: true

  has_many :notifications,  dependent: :destroy,     class_name: Event::Subscription::Notification
  has_many :subscriptions,  through: :notifications, class_name: Event::Subscription
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :source,  presence: true, unless: -> { action && action.to_sym == :deleted }

  # For Hash only
  serialize :data

  # Scopes
  scope :with_source, ->(source) { where(source_id: source, source_type: source.class.name) }
  scope :recent, -> { order("created_at DESC") }
  scope :with_target, ->(target) { where(target_id: target, target_type: target.class.name) }
end
