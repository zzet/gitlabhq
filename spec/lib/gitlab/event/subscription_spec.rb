require 'spec_helper'

describe Gitlab::Event::Subscription do
  it "should respond to :subscribe" do
    Gitlab::Event::Subscription.should respond_to :subscribe
  end
end
