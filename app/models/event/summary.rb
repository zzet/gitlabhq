# == Schema Information
#
# Table name: event_summaries
#
#  id             :integer          not null, primary key
#  title          :string(255)
#  state          :string(255)
#  period         :string(255)
#  last_send_date :datetime
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#

class Event::Summary < ActiveRecord::Base
  extend Enumerize

  attr_accessible :title, :description, :period, :state_event

  belongs_to :user
  has_many :summary_entity_relationships, dependent: :destroy, class_name: Event::SummaryEntityRelationship
  has_many :entities, through: :summary_entity_relationships

  enumerize :period, in: [:daily, :weekly, :monthly], default: :daily

  validates :title, presence: true
  validates :period, presence: true

  state_machine :state, initial: :enabled do
    state :disabled
    state :enabled

    event :disable do
      transition enabled: :disabled
    end

    event :enable do
      transition disabled: :enabled
    end
  end

  scope :daily,   -> { where(period: :daily) }
  scope :weekly,  -> { where(period: :weekly) }
  scope :monthly, -> { where(period: :monthly) }

  scope :by_user, ->(user) {
    where(user_id: user.id)
  }

  scope :current_daily, -> {
    date = Time.zone.now - 1.day
    where(period: :daily).where('last_send_date IS NULL OR last_send_date <= ?', date)
  }

  scope :current_weekly, -> {
    date = Time.zone.now - 1.week
    where(period: :weekly).where('last_send_date IS NULL OR last_send_date <= ?', date)
  }

  scope :current_monthly, -> {
    date = Time.zone.now - 1.month
    where(period: :monthly).where('last_send_date IS NULL OR last_send_date <= ?', date)
  }

  scope :by_subscription, ->(subscription) {
    by_user(subscription.user).
      joins(:summary_entity_relationships).
      where(event_summary_entity_relationships: { entity_id: subscription.target_id, entity_type: subscription.target_type })
  }

  def events_for(to_time)
    from = from_time
    to = to_time

    result = []
    summary_entity_relationships.each do |entity_relation|
      # TODO. Add filter by action here
      events = Event.where(target_id: entity_relation.entity_id,
                           target_type: entity_relation.entity_type,
                           created_at: from..to).order(created_at: :asc)
      if entity_relation.options.any?
        events = events.where(source_type: entity_relation.options.map(&:camelize))
      end
      result << events unless events.blank?
    end

    result.flatten.uniq
  end

  private

  def from_time
    if last_send_date
      last_send_date
    else
      case period
      when :daily
        Time.zone.now - 1.day
      when :weekly
        Time.zone.now - 1.week
      when :monthly
        Time.zone.now - 1.month
      else
        Time.zone.now - 1.week
      end
    end
  end
end
