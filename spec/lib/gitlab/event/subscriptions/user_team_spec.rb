require 'spec_helper'

describe Gitlab::Event::Subscriptions::UserTeam do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscriptions::UserTeam.should respond_to :can_subscribe?
  end

  describe "UserTeam subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist user_team changes" do
      source = create :user_team
      target = source
      action = :updated

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all user_teams changes by subscribe with symbol" do
      source = :user_team
      target = create :user_team
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all user_teams changes by subscribe with Class name" do
      source = UserTeam
      target = create :user_team
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist user_team :users_project adds" do
      target = create :user_team
      source = :users_project
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
