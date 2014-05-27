# == Schema Information
#
# Table name: event_auto_subscriptions
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  target         :string(255)
#  namespace_id   :integer
#  namespace_type :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class Event::AutoSubscription < ActiveRecord::Base
  attr_accessible :namespace, :namespace_id, :namespace_type, :target, :user_id

  belongs_to :user
  belongs_to :namespace, polymorphic: true
  has_many :subscriptions, class_name: Event::Subscription

  validates :target, presence: true
  validates :user,   presence: true

  scope :with_namespace,   ->(n) { n.present? ? where(namespace_type: n.class.name, namespace_id: n.id) : where.not(namespace_id: nil) }
  scope :without_namespace,   -> { where(namespace_id: nil) }
  scope :with_target, ->(target) { where(target: target) }
  scope :adjacent, ->(type, id) { where(namespace_type: type, namespace_id: id)}
end
