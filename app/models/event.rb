class Event < ActiveRecord::Base
  include Actionable

  attr_accessible :action, :data, :target_id, :target_type, :author_id, :target, :author


  belongs_to :author, class_name: User
  belongs_to :target, polymorphic: true

  has_many :notifications,  dependent: :destroy,     class_name: Event::Subscription::Notification
  has_many :subscriptions,  through: :notifications, class_name: Event::Subscription
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :target,  presence: true

  scope :with_target, ->(target) { where(target_id: target, target_type: target.class.name) }
end
