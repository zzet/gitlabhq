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

require 'spec_helper'

describe Event::SubscriptionOption do
  pending "add some examples to (or delete) #{__FILE__}"
end
