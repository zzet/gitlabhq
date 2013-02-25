require 'spec_helper'

describe Notifications::SubscriptionsController do
  let(:project) { create(:project) }
  let(:group)   { create(:group) }
  let(:user)    { create(:user) }

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
  end
end
