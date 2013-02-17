require 'spec_helper'

describe Gitlab::Event::Builder::Base do
  it "should respond that can build with exceprtion" do
    -> { Gitlab::Event::Builder::Base.can_build?("action", {}) }.should raise_error(NotImplementedError)
  end

  it "should build action from hash" do
    -> { Gitlab::Event::Builder::Base.build("action", nil, nil, nil) }.should raise_error(NotImplementedError)
  end

  it "should respond that know action with false" do
    action_list = [:one, :second, :test]
    action = "gitlab.create.action"
    Gitlab::Event::Builder::Base.known_action?(action_list, action).should be_false
  end

  it "should respond that know action with false" do
    action_list = [:create, :one, :second, :test]
    action = "gitlab.create.action"
    Gitlab::Event::Builder::Base.known_action?(action_list, action).should be_true
  end
end
