class Event < ActiveRecord::Base
  include Actionable

  attr_accessible :action, :data, :source_id, :source_type, :author_id, :source, :author


  belongs_to :author, class_name: User
  belongs_to :source, polymorphic: true

  has_many :notifications,  dependent: :destroy,     class_name: Event::Subscription::Notification
  has_many :subscriptions,  through: :notifications, class_name: Event::Subscription
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :source,  presence: true

  scope :with_source, ->(source) { where(source_id: source, source_type: source.class.name) }
end
