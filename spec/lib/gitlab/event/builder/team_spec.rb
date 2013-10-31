require 'spec_helper'

describe Gitlab::Event::Builder::Team do
  before do
    ActiveRecord::Base.observers.disable :all

    @user = create :user
    @team = create :team, creator: @user
    @data = {source: @team, user: @user, data: @team}
    @action = "gitlab.created.team"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Team.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Team.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
