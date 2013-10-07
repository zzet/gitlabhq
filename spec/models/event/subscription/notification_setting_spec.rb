# == Schema Information
#
# Table name: event_subscription_notification_settings
#
#  id                     :integer          not null, primary key
#  user_id                :integer
#  own_changes            :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  adjacent_changes       :boolean
#  brave                  :boolean
#  subscribe_if_owner     :boolean
#  subscribe_if_developer :boolean
#

require 'spec_helper'

describe Event::Subscription::NotificationSetting do
  pending "add some examples to (or delete) #{__FILE__}"
end
