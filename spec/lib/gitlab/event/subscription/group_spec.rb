require 'spec_helper'

describe Gitlab::Event::Subscription::Group do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscription::Group.should respond_to :can_subscribe?
  end

  describe "Group subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist group changes" do
      source = create :group
      target = source
      action = :updated

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all groups changes by subscribe with symbol" do
      source = :group
      target = create :group
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all groups changes by subscribe with Class name" do
      source = Group
      target = create :group
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist group :project adds" do
      target = create :group
      source = :project
      action = :created

      Gitlab::Event::Subscription.subscribe(@user, action, target, source)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
