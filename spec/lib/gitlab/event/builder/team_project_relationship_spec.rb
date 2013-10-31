require 'spec_helper'

describe Gitlab::Event::Builder::TeamProjectRelationship do
  before do
    ActiveRecord::Base.observers.disable :all

    @user     = create :user
    @team     = create :team, creator: @user
    @project  = create :project, creator: @user
    @team_project_relationship = create :team_project_relationship, team: @team, project: @project
    @data     = {source: @team_project_relationship, user: @user, data: @team_project_relationship}
    @action   = "gitlab.created.team_project_relationship"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::TeamProjectRelationship.can_build?(@action, @data[:source]).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::TeamProjectRelationship.build(@action, @data[:source], @data[:user], @data[:data])
  end
end
