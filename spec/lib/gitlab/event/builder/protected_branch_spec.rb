require 'spec_helper'

describe Gitlab::Event::Builder::ProtectedBranch do
  before do
    @protected_branch = create :protected_branch
    @user = create :user
    @data = {target: @protected_branch, user: @user, data: @protected_branch}
    @action = "gitlab.created.protected_branch"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::ProtectedBranch.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::ProtectedBranch.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
