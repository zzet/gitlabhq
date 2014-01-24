# == Schema Information
#
# Table name: event_subscription_notifications
#
#  id                 :integer          not null, primary key
#  event_id           :integer
#  subscription_id    :integer
#  notification_state :string(255)
#  notified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  subscriber_id      :integer
#

require 'spec_helper'

describe Event::Subscription::Notification do
  pending "add some examples to (or delete) #{__FILE__}"
end
