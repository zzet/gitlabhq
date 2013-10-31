require 'spec_helper'

describe Gitlab::Event::Builder::TeamUserRelationship do
  before do
    ActiveRecord::Base.observers.disable :all

    @user = create :user
    @team = create :team, creator: @user
    @team_user_relationship = create :team_user_relationship, team: @team, user: @user
    @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}
    @action = "gitlab.created.team_user_relationship"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::TeamUserRelationship.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::TeamUserRelationship.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
