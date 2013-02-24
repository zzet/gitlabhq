require 'spec_helper'

describe Gitlab::Event::Action do
  it "should trigger action" do
    Gitlab::Event::Action.should respond_to :trigger
  end
end

