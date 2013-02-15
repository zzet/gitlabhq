require 'spec_helper'

describe Gitlab::Event::Builder::UserTeamUserRelationship do
  before do
    ActiveRecord::Base.observers.disable :all

    @user_team_user_relationship = create :user_team_user_relationship
    @user = create :user
    @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}
    @action = "gitlab.created.user_team_user_relationship"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::UserTeamUserRelationship.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::UserTeamUserRelationship.build(@action, @data[:source], @data[:user], @data[:data])
  end


end
