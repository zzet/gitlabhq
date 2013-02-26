require 'spec_helper'

describe Gitlab::Event::Subscription do
  it "should respond to :subscribe" do
    Gitlab::Event::Subscription.should respond_to :subscribe
  end

  describe "Subscribe User on different events" do
    before do
      @user = create :user
      @key = create :key, user: @user
      @project = create :project, creator: @user
    end

    it "should can subscribe user on self changes" do
      Gitlab::Event::Subscription.can_subscribe?(@user, :updated, @user, @user).should be_true
      Gitlab::Event::Subscription.can_subscribe?(@user, :deleted, @user, @user).should be_true

      Gitlab::Event::Subscription.can_subscribe?(@user, :updated, @user, :user).should be_true
      Gitlab::Event::Subscription.can_subscribe?(@user, :deleted, @user, :user).should be_true

      Gitlab::Event::Subscription.can_subscribe?(@user, :created, @user, @key).should be_true
      Gitlab::Event::Subscription.can_subscribe?(@user, :updated, @user, @key).should be_true
      Gitlab::Event::Subscription.can_subscribe?(@user, :deleted, @user, @key).should be_true

      Gitlab::Event::Subscription.can_subscribe?(@user, :created, @user, :key).should be_true
      Gitlab::Event::Subscription.can_subscribe?(@user, :updated, @user, :key).should be_true
      Gitlab::Event::Subscription.can_subscribe?(@user, :deleted, @user, :key).should be_true
    end

    it "should subscribe user on all self changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :all, @user, @user)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on updated self changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :updated, @user, @user)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on deleted self changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :deleted, @user, @user)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on all self changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :all, @user, :user)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on updated self changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :updated, @user, :user)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on deleted self changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :deleted, @user, :user)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on all key changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :all, @user, @key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on created key changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :created, @user, @key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on updated key changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :updated, @user, @key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on deleted key changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :deleted, @user, @key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on all key changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :all, @user, :key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on created key changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :created, @user, :key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on updated key changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :updated, @user, :key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on all deleted changes by symbol" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :deleted, @user, :key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end

    it "should subscribe user on all self changes by object" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :all, @user, :key)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank

      Gitlab::Event::Subscription.subscribe(@user, :updated, @user, @user)
      @new_subsriprtions = ::Event::Subscription.by_user(@user)
      @new_subsriprtions.count.should == 2

      Gitlab::Event::Subscription.unsubscribe(@user, :all, @user, :key)
      @subscriptions_after_unsubscribe = ::Event::Subscription.by_user(@user)
      @subscriptions_after_unsubscribe.should_not be_blank
      @subscriptions_after_unsubscribe.count.should == 1
      @subscriptions_after_unsubscribe.first.action == :updated
    end

    it "should subscribe user on all new targets by target type" do
      ::Event::Subscription.destroy_all
      Gitlab::Event::Subscription.subscribe(@user, :all, :project, :all)
      @subscriptions = ::Event::Subscription.by_user(@user)
      @subscriptions.should_not be_blank
    end
  end
end
