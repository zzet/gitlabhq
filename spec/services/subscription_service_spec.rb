require 'spec_helper'

describe SubscriptionService do
  it "should respond to subscribe method" do
    SubscriptionService.should respond_to :subscribe
  end
end
