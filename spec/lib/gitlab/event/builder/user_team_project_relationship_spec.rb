require 'spec_helper'

describe Gitlab::Event::Builder::UserTeamProjectRelationship do
  before do
    @user_team_project_relationship = create :user_team_project_relationship
    @user = create :user
    @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}
    @action = "gitlab.created.user_team_project_relationship"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::UserTeamProjectRelationship.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::UserTeamProjectRelationship.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
