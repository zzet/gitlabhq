require 'spec_helper'

describe Gitlab::Event::Builder::SystemHook do
  before do
    ActiveRecord::Base.observers.disable :all
    SystemHook.observers.enable :activity_observer

    @system_hook = create :system_hook
    @user = create :user
    @data = {source: @system_hook, user: @user, data: @system_hook}
    @action = "gitlab.created.system_hook"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::SystemHook.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::SystemHook.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
