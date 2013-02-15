require 'spec_helper'

describe Gitlab::Event::Builder::Wiki do
  before do
    ActiveRecord::Base.observers.disable :all

    @wiki = create :wiki
    @user = create :user
    @data = {source: @wiki, user: @user, data: @wiki}
    @action = "gitlab.created.wiki"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Wiki.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Wiki.build(@action, @data[:source], @data[:user], @data[:data])
  end

end
