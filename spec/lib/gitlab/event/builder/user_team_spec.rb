require 'spec_helper'

describe Gitlab::Event::Builder::UserTeam do
  before do
    @user_team = create :user_team
    @user = create :user
    @data = {target: @user_team, user: @user, data: @user_team}
    @action = "gitlab.created.user_team"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::UserTeam.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::UserTeam.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
