class Event::Subscription < ActiveRecord::Base
  include Actionable

  attr_accessible :action,
                  :last_notified_at,
                  :notification_interval,
                  :target_id, :target_type, :target, :target_category,
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
  validates :target_category, presence: true, if: :check_presence_of_target_and_source_category

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

  scope :by_action, ->(action) { where(action: action.to_sym) }
  scope :by_user, ->(subscriber) { where(user_id: subscriber.id) }
  scope :by_source, ->(source) { where(source_id: source.id, source_type: source.class.name) }
  scope :by_target, ->(target) { where(target_id: target.id, target_type: target.class.name) }
  scope :by_target_category, ->(target) { where(target_category: target) }

  scope :by_source_type, ->(source_type) do
    source_type = source_type.to_s.camelize
    est = self.arel_table
    where(est[:source_type].eq(source_type).or(est[:source_category].in([source_type, :all])))
  end

  scope :with_source, -> { where("source_id IS NOT NULL") }
  scope :without_source, -> { where(source_id: nil) }
  scope :with_target, -> { where("target_type IS NOT NULL") }
  scope :with_target_category, -> { where("target_category IS NOT NULL") }

  class << self
    def global_entity_to_subscription
      [:project, :group, :user_team, :user]
    end
  end
end
