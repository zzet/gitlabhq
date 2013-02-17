require 'spec_helper'

describe Gitlab::Event::Builder::UserTeamUserRelationship do
  before do
    @user_team_user_relationship = create :user_team_user_relationship
    @user = create :user
    @data = {target: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}
    @action = "gitlab.created.user_team_user_relationship"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::UserTeamUserRelationship.can_build?(@action, @data[:target]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::UserTeamUserRelationship.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
