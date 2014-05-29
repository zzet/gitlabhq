# == Schema Information
#
# Table name: event_subscription_options
#
#  id              :integer          not null, primary key
#  subscription_id :integer
#  source          :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class Event::SubscriptionOption < ActiveRecord::Base
  attr_accessible :source, :subscription_id

  belongs_to :subscription, class_name: Event::Subscription

  validates :subscription, presence: true
  validates :source,       presence: true, uniqueness: { scope: :subscription_id }
end
