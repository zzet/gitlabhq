# == Schema Information
#
# Table name: event_subscriptions
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  action                :string(255)
#  target_id             :integer
#  target_type           :string(255)
#  source_id             :integer
#  source_type           :string(255)
#  source_category       :string(255)
#  notification_interval :integer
#  last_notified_at      :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  target_category       :string(255)
#

class Event::Subscription < ActiveRecord::Base
  attr_accessible :target_id, :target_type, :target,
                  :user_id, :user,
                  :last_notified_at, :notification_interval, :options

  # Relations
  belongs_to :user
  belongs_to :target, polymorphic: true
  belongs_to :auto_subscription,  class_name: Event::AutoSubscription
  has_many :notifications

  # Validations
  validates :user,   presence: true
  validates :target, presence: true
  validates :target_id, uniqueness: { scope: [:user_id, :target_type] }

  # Scopes
  scope :by_user, ->(subscriber) { where(user_id: subscriber.id) }
  scope :by_target, ->(target) { where(target_id: target.id, target_type: target.class.name) }
  scope :by_source, ->(source) { where("'#{source}' = ANY (options)") }
  scope :by_event_target, ->(event) { where(target_id: event.target_id, target_type: event.target_type) }
  scope :by_source_type, ->(source) { by_source(source.underscore) }


  scope :with_target, -> { where("target_type IS NOT NULL").uniq_by_target }
  scope :with_target_category, -> { where("target_category IS NOT NULL").uniq_by_target }
  scope :uniq_by_target, -> { select("DISTINCT ON (event_subscriptions.target_type, event_subscriptions.target_id, event_subscriptions.user_id) event_subscriptions.*") }

  # All subscriptions by action and source type
  scope :base, ->(event) { where(action: event.action, source_type: event.source_type) }
  # All subscriptions on surrent event (current source)
  scope :on_event, ->(event) { base(event).where(source_id: event.source_id) }
  # All subscriptions by related target
  scope :on_related_event, ->(event) { base(event).where(target_type: event.target_type, target_id: event.target_id) }

  scope :by_action, ->(action) { where(action: action.to_sym) }
  scope :by_target_category, ->(target) { where(target_category: target).uniq_by_target }

  class << self
    def global_entity_to_subscription
      [:project, :group, :team, :user]
    end
  end

  def with_adjacent_for?(user, source)
    self.class.by_user(user).by_target(self.target).by_source_type(source).many?
  end
end
