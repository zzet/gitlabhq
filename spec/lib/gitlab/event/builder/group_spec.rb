require 'spec_helper'

describe Gitlab::Event::Builder::Group do
  before do
    ActiveRecord::Base.observers.disable :all
    @group = create :group
    @user = create :user
    @data = {source: @group, user: @user, data: @group}
    @action = "gitlab.created.group"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Group.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Group.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
