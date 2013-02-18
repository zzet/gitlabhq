class Event::Subscription < ActiveRecord::Base
  include Actionable

  attr_accessible :action,
                  :last_notified_at,
                  :notification_interval,
                  :target_id, :target_type, :target,
                  :source_id, :source_type, :source, :source_category,
                  :user_id, :user

  # Relations
  belongs_to :user
  belongs_to :target, polymorphic: true # Aggregation events, for example Project
  belongs_to :source, polymorphic: true # That generated action, for example Issue
  has_many :notifications, dependent: :destroy

  # Validations
  validates :user, presence: true
  validates :source, presence: true, if: :check_presence_of_target_and_source_category
  validates :target, presence: true, if: :check_presence_of_source_and_source_category
  validates :source_category, presence: true, if: :check_presence_of_target_and_source

  # Custom validations
  def check_presence_of_target_and_source
    target.blank? && source.blank?
  end

  def check_presence_of_target_and_source_category
    target.blank? && source_category.blank?
  end

  def check_presence_of_source_and_source_category
    (source.blank? && source_category.blank?) || (source.present? && source_category.blank?)
  end

  # Scopes
  # All subscriptions by action and source type
  scope :base, ->(event) { where(action: event.action, source_type: event.source_type) }
  # All subscriptions on surrent event (current source)
  scope :on_event, ->(event) { base(event).where(source_id: event.source_id) }
  # All subscriptions by related target
  scope :on_related_event, ->(event) { base(event).where(target_type: event.target_type, target_id: event.target_id) }

end
