require 'spec_helper'

describe Gitlab::Event::Builder::WebHook do
  before do
    @web_hook = create :web_hook
    @user = create :user
    @data = {target: @web_hook, user: @user, data: @web_hook}
    @action = "gitlab.created.web_hook"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::WebHook.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::WebHook.build(@action, @data[:target], @data[:user], @data[:data])
  end

end
