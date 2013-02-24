require 'spec_helper'

describe Gitlab::Event::Builder::Base do
  it "should respond that can build with exceprtion" do
    -> { Gitlab::Event::Builder::Base.can_build?("action", {}) }.should raise_error(NotImplementedError)
  end

  it "should build action from hash" do
    -> { Gitlab::Event::Builder::Base.build("action", nil, nil, nil) }.should raise_error(NotImplementedError)
  end
end
