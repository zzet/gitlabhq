require 'spec_helper'

describe Gitlab::Event::Subscriptions::Base do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscriptions::Base.should respond_to :can_subscribe?
  end
end
