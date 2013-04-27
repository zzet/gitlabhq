require 'spec_helper'

describe Gitlab::Event::Builder::Milestone do
  before do
    ActiveRecord::Base.observers.disable :all

    @milestone = create :milestone
    @user = create :user
    @data = {source: @milestone, user: @user, data: @milestone}
    @action = "gitlab.created.milestone"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Milestone.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Milestone.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
