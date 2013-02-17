require 'spec_helper'

describe Gitlab::Event::Builder::Wiki do
  before do
    @wiki = create :wiki
    @user = create :user
    @data = {target: @wiki, user: @user, data: @wiki}
    @action = "gitlab.created.wiki"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Wiki.can_build?(@action, @data[:target]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Wiki.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
