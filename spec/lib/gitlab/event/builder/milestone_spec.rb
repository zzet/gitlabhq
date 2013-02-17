require 'spec_helper'

describe Gitlab::Event::Builder::Milestone do
  before do
    @milestone = create :milestone
    @user = create :user
    @data = {target: @milestone, user: @user, data: @milestone}
    @action = "gitlab.created.milestone"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Milestone.can_build?(@action, @data[:target]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Milestone.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
