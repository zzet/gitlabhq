require 'spec_helper'

describe Gitlab::Event::Subscriptions::Issue do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscriptions::Issue.should respond_to :can_subscribe?
  end

  describe "Issue subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist issue changes" do
      source = create :issue
      target = source
      action = :updated

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all issues changes by subscribe with symbol" do
      source = :issue
      target = create :project, creator: @user
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all issues changes by subscribe with Class name" do
      source = Issue
      target = create :project, creator: @user
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist issue :note adds" do
      target = create :issue
      source = :note
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
