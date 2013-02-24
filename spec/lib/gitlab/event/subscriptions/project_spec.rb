require 'spec_helper'

describe Gitlab::Event::Subscriptions::Project do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscriptions::Project.should respond_to :can_subscribe?
  end

  describe "Project subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist project changes" do
      source = create :project
      target = source
      action = :updated

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all projects changes by subscribe with symbol" do
      source = :project
      target = create :project
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all projects changes by subscribe with Class name" do
      source = Project
      target = create :project
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist project :issue adds" do
      target = create :project
      source = :issue
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
