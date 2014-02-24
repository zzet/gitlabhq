class Event::AutoSubscription < ActiveRecord::Base
  attr_accessible :namespace, :namespace_id, :namespace_type, :target, :user_id

  belongs_to :user
  belongs_to :namespace, polymorphic: true
  has_many :subscriptions, class_name: Event::Subscription

  validates :target, presence: true, uniqueness: { scope: [:namespace_id, :namespace_type] }
  validates :user,   presence: true

  scope :with_namespace,   ->(n) { n.present? ? where(namespace_type: n.class.name, namespace_id: n.id) : where.not(namespace_id: nil) }
  scope :without_namespace,   -> { where(namespace_id: nil) }
  scope :with_target, ->(target) { where(target: target) }
  scope :adjacent, ->(type, id) { where(namespace_type: type, namespace_id: id)}
end
