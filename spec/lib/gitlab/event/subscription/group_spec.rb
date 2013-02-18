require 'spec_helper'

describe Gitlab::Event::Subscriptions::Group do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscriptions::Group.should respond_to :subscribe
  end

  describe "Group subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist group changes" do
      source = create :group
      target = source
      action = :updated

      Gitlab::Event::Subscriptions::Group.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all groups changes by subscribe with symbol" do
      source = :group
      target = Group
      action = :created

      Gitlab::Event::Subscriptions::Group.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all groups changes by subscribe with Class name" do
      source = Group
      target = Group
      action = :created

      Gitlab::Event::Subscriptions::Group.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist group :project adds" do
      target = create :group
      source = :project
      action = :created

      Gitlab::Event::Subscriptions::Group.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
