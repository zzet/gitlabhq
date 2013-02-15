require 'spec_helper'

describe Gitlab::Event::Builder::User do
  before do
    @user = create :user
    @user = create :user
    @data = {target: @user, user: @user, data: @user}
    @action = "gitlab.created.user"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::User.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::User.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
