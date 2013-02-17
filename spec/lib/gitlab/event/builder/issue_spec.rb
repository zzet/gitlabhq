require 'spec_helper'

describe Gitlab::Event::Builder::Issue do
  before do
    @user = create :user
    @project = create :project, creator: @user
    @issue = create :issue, project: @project

    @data = {target: @issue, user: @user, data: @issue}
    @action = "gitlab.created.issue"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Issue.can_build?(@action, @data[:target]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Issue.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
