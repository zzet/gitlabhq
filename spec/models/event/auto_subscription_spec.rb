# == Schema Information
#
# Table name: event_auto_subscriptions
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  target         :string(255)
#  namespace_id   :integer
#  namespace_type :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

require 'spec_helper'

describe Event::AutoSubscription do
  pending "add some examples to (or delete) #{__FILE__}"
end
