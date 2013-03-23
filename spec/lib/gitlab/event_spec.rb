require 'spec_helper'

describe Gitlab::Event do
  it "should create events from action" do
    Gitlab::Event.should respond_to :create_events
  end
end
