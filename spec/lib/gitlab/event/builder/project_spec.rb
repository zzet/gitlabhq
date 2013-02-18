require 'spec_helper'

describe Gitlab::Event::Builder::Project do
  before do
    @project = create :project
    @user = create :user
    @data = {source: @project, user: @user, data: @project}
    @action = "gitlab.created.project"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Project.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Project.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
