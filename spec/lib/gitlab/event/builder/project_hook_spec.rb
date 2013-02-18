require 'spec_helper'

describe Gitlab::Event::Builder::ProjectHook do
  before do
    @project_hook = create :project_hook
    @user = create :user
    @data = {source: @project_hook, user: @user, data: @project_hook}
    @action = "gitlab.created.project_hook"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::ProjectHook.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::ProjectHook.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
