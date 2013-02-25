require 'spec_helper'

describe Notifications::SubscriptionsController do
  let(:project)   { create(:project) }
  let(:group)     { create(:group) }
  let(:user_team) { create(:user_team) }
  let(:user)      { create(:user) }

  before do
    sign_in(user)
  end

  describe "#create" do
    render_views

    it "should register subscription on project" do
      post :create, :entity => { id: project.id,  type: :project}, format: :html

      project.watched_by?(user).should be_true 
    end

    it "should register subscription on group" do
      post :create, :entity => { id: group.id,  type: :group}, format: :html

      group.watched_by?(user).should be_true 
    end

    it "should register subscription on team" do
      post :create, :entity => { id: user_team.id,  type: :user_team}, format: :html

      user_team.watched_by?(user).should be_true 
    end

    it "should unregister subscription on project" do
      SubscriptionService.subscribe(user, :all, project, :all)

      delete :destroy, :entity => { id: project.id,  type: :project}, format: :html

      project.watched_by?(user).should be_false 
    end

    it "should unregister subscription on group" do
      SubscriptionService.subscribe(user, :all, group, :all)

      delete :destroy, :entity => { id: group.id,  type: :group}, format: :html

      group.watched_by?(user).should be_false 
    end

    it "should unregister subscription on team" do
      SubscriptionService.subscribe(user, :all, user_team, :all)

      delete :destroy :entity => { id: user_team.id,  type: :user_team}, format: :html

      user_team.watched_by?(user).should be_false 
    end
  end
end
