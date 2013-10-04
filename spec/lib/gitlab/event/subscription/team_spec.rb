require 'spec_helper'

describe Gitlab::Event::Subscription::Team do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscription::Team.should respond_to :can_subscribe?
  end

  describe "Team subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist team changes" do
      source = create :team
      target = source
      action = :updated

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all teams changes by subscribe with symbol" do
      source = :team
      target = create :team
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all teams changes by subscribe with Class name" do
      source = Team
      target = create :team
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist team :users_project adds" do
      target = create :team
      source = :users_project
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
