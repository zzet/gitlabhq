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
  has_many :subscriptions,  dependent: :destroy, through: :notifications, class_name: Event::Subscription
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :source,  presence: true, unless: -> { action && (deleted_event? || push_event?) }

  # Custom validators
  def push_event?
    return false unless Event::Action.push_action?(action)
    return true if data["repository"]
  end

  def deleted_event?
     [:deleted, :resigned].include? action.to_sym
  end

  # For Hash only
  #serialize :data

  # Scopes
  scope :with_source, ->(source) { where(source_id: source, source_type: source.class.name) }
  scope :recent, -> { order("created_at DESC") }
  scope :with_target, ->(target) { where(target_id: target, target_type: target.class.name) }
  scope :with_push, -> { where(source_type: "Push_summary") }

  def deleted_related?
    target && deleted_event? && source_type.blank?
  end

  def deleted_self?
    source.blank? && deleted_event? && target.blank?
  end

  def full?
    source.present? && target.present?
  end

end
