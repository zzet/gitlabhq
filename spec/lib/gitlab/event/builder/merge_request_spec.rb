require 'spec_helper'

describe Gitlab::Event::Builder::MergeRequest do
  before do
    ActiveRecord::Base.observers.disable :all

    @merge_request = create :merge_request
    @user = create :user
    @data = {source: @merge_request, user: @user, data: @merge_request}
    @action = "gitlab.created.merge_request"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::MergeRequest.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::MergeRequest.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
