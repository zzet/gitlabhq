require 'spec_helper'

describe Gitlab::Event::Builder::MergeRequest do
  before do
    @merge_request = create :merge_request
    @user = create :user
    @data = {target: @merge_request, user: @user, data: @merge_request}
    @action = "gitlab.created.merge_request"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::MergeRequest.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::MergeRequest.build(@action, @data[:target], @data[:user], @data[:data])
  end

end
