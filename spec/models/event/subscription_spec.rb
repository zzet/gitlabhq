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

require 'spec_helper'

describe Event::Subscription do
  pending "add some examples to (or delete) #{__FILE__}"
end
