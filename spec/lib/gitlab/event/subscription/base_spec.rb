require 'spec_helper'

describe Gitlab::Event::Subscription::Base do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscription::Base.should respond_to :can_subscribe?
  end
end
