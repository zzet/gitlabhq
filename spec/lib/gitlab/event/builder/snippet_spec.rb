require 'spec_helper'

describe Gitlab::Event::Builder::Snippet do
  before do
    ActiveRecord::Base.observers.disable :all

    @snippet = create :snippet
    @user = create :user
    @data = {source: @snippet, user: @user, data: @snippet}
    @action = "gitlab.created.snippet"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Snippet.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Snippet.build(@action, @data[:source], @data[:user], @data[:data])
  end

end
