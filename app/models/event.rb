# == Schema Information
#
# Table name: events
#
#  id              :integer          not null, primary key
#  author_id       :integer
#  action          :string(255)
#  source_id       :integer
#  source_type     :string(255)
#  target_id       :integer
#  target_type     :string(255)
#  data            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_event_id :integer
#

class Event < ActiveRecord::Base
  include Actionable

  attr_accessible :action,    :system_action, :data,
                  :source_id, :source_type, :source,
                  :target_id, :target_type, :target,
                  :author_id, :author

  belongs_to :target, polymorphic: true
  belongs_to :source, polymorphic: true
  belongs_to :author,       class_name: User
  belongs_to :parent_event, class_name: Event

  has_many :notifications,  dependent: :destroy,     class_name: Event::Subscription::Notification
  has_many :subscriptions,  dependent: :destroy,     class_name: Event::Subscription, through: :notifications
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :source,  presence: true

  # For Hash only
  #serialize :data

  # Scopes
  scope :with_source, ->(source) { where(source_id: source, source_type: source.class.name) }
  scope :recent, -> { order("created_at DESC") }
  scope :with_target, ->(target) { where(target_id: target, target_type: target.class.name) }
  scope :with_push, -> { where(source_type: Push) }

  def deleted_event?
    if system_action.present?
      system_action.to_sym == :destroy
    end
  end

  def push_event?
    return false unless Event::Action.push_action?(action)
    return true if data["repository"]
  end

  def deleted_related?
    deleted_event? && target && source_type.blank?
  end

  def deleted_self?
    deleted_event? && source.blank?  && target.blank?
  end

  def full?
    source.present? && target.present?
  end
end
