require 'spec_helper'

describe SubscriptionService do
  it "should respond to subscribe method" do
    SubscriptionService.should respond_to :subscribe
  end

  it "should respond to unsubscribe method" do
    SubscriptionService.should respond_to :unsubscribe
  end

  describe "Subscribe service" do
    before do
      @user = create :user
      @group = create :group, owner: @user
      @project = create :project, namespace: @group, creator: @user
    end

    it "should subscribe user on group notifications" do
      subscriptions_count = Event::Subscription.by_user(@user).count
      SubscriptionService.subscribe(@user, :all, @group, :all)

      subscriptions_count_after_subscribe = Event::Subscription.by_user(@user).count
      (subscriptions_count_after_subscribe - subscriptions_count).should == 1
    end

    it "should unsubscribe user on group notifications" do
      SubscriptionService.subscribe(@user, :all, @group, :all)
      subscriptions_count = Event::Subscription.by_user(@user).count

      SubscriptionService.unsubscribe(@user, :all, @group, :all)
      subscriptions_count_after_unsubscribe = Event::Subscription.by_user(@user).count

      (subscriptions_count - subscriptions_count_after_unsubscribe).should == 1
    end

    it "should subscribe user on project notifications on group" do
      subscriptions_count = Event::Subscription.by_user(@user).count
      SubscriptionService.subscribe(@user, :all, @group, :all)
      SubscriptionService.subscribe(@user, :all, @group, :project)

      subscriptions_count_after_subscribe = Event::Subscription.by_user(@user).count
      (subscriptions_count_after_subscribe - subscriptions_count).should == 2

      SubscriptionService.unsubscribe(@user, :all, @group, :project)
      subscriptions_count_after_unsubscribe = Event::Subscription.by_user(@user).count

      (subscriptions_count_after_subscribe - subscriptions_count_after_unsubscribe).should == 1
      Event::Subscription.by_user(@user).first.source_category.should == "all"

      SubscriptionService.unsubscribe(@user, :all, @group, :all)
      subscriptions_count_after_unsubscribe = Event::Subscription.by_user(@user).count

      (subscriptions_count_after_subscribe - subscriptions_count_after_unsubscribe).should == 2
    end

    it "should unsubscribe from all notifications" do
      subscriptions_count = Event::Subscription.by_user(@user).count
      SubscriptionService.subscribe(@user, :all, @group, :all)
      SubscriptionService.subscribe(@user, :all, @group, :project)

      subscriptions_count_after_subscribe = Event::Subscription.by_user(@user).count
      (subscriptions_count_after_subscribe - subscriptions_count).should == 2

      SubscriptionService.unsubscribe(@user, :all, @group, :all)
      subscriptions_count_after_unsubscribe = Event::Subscription.by_user(@user).count

      (subscriptions_count - subscriptions_count_after_unsubscribe).should == 0
    end

    it "should unsubscribe from all adjacent notifications" do
      subscriptions_count = Event::Subscription.by_user(@user).count
      SubscriptionService.subscribe(@user, :all, @group, :all)
      SubscriptionService.subscribe(@user, :all, @group, :project)

      subscriptions_count_after_subscribe = Event::Subscription.by_user(@user).count
      (subscriptions_count_after_subscribe - subscriptions_count).should == 2

      SubscriptionService.unsubscribe_from_adjacent_sources(@user)
      subscriptions_count_after_unsubscribe = Event::Subscription.by_user(@user).count

      (subscriptions_count_after_subscribe - subscriptions_count_after_unsubscribe).should == 1
    end

  end
end
