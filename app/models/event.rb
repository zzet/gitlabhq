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
  has_many :subscriptions,  dependent: :destroy,     class_name: Event::Subscription, through: :notifications
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
  store :data

  # Scopes
  scope :with_source_or_target, ->(entity) do
    where(arel_table[:source_type].eq(entity.class.name)
           .and(arel_table[:source_id].eq(entity.id))
           .or(arel_table[:target_type].eq(entity.class.name)
               .and(arel_table[:target_id].eq(entity.id)))).uniq
  end

  scope :with_source_or_target_type, ->(entity_type) do
    where(arel_table[:source_type].eq(entity_type.to_s.camelize)
          .or(arel_table[:target_type].eq(entity_type.to_s.camelize))).uniq
  end

  scope :with_source,     ->(source) { where(source_id: source, source_type: source.class.name) }

  scope :recent,          -> { order("created_at DESC") }
  scope :with_target,     ->(target) { where(target_id: target, target_type: target.class.name) }
  scope :with_push,       -> { where(source_type: "PushSummary") }

  scope :watched_by_user, ->(user) { u.notifications.includes(:event) }

  scope :group_events,         ->(entity) { with_source_or_target(entity) }
  scope :team_events,          ->(entity) { with_source_or_target(entity) }
  scope :project_events,       ->(entity) { with_source_or_target(entity) }
  scope :issue_event,          ->(entity) { with_source_or_target(entity) }
  scope :merge_request_events, ->(entity) { with_source_or_target(entity) }
  scope :note_events,          ->(entity) { with_source_or_target(entity) }
  scope :code_events,          ->(entity) { with_source_or_target(entity) }

  scope :group_type_events,         -> { with_source_or_target_type(:group) }
  scope :team_type_events,          -> { with_source_or_target_type(:user_team) }
  scope :project_type_events,       -> { with_source_or_target_type(:project) }
  scope :issue_type_event,          -> { with_source_or_target_type(:issue) }
  scope :merge_request_type_events, -> { with_source_or_target_type(:merge_request) }
  scope :note_type_events,          -> { with_source_or_target_type(:note) }
  scope :code_type_events,          -> { with_source_or_target_type(:push_summary) }

  scope :sorted_by_activity,        -> { order("created_at DESC") }

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
