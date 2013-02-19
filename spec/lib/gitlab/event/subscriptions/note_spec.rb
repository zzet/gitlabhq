require 'spec_helper'

describe Gitlab::Event::Subscriptions::Note do
  it "should respond to :subscribe method" do
    Gitlab::Event::Subscriptions::Note.should respond_to :subscribe
  end

  describe "Note subscribe" do
    before do
      @user = create :user
    end

    it "should subscribe user on exist note changes" do
      source = create :note
      target = source
      action = :updated

      Gitlab::Event::Subscriptions::Note.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all notes changes by subscribe with symbol" do
      source = :note
      target = Note
      action = :created

      Gitlab::Event::Subscriptions::Note.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on all notes changes by subscribe with Class name" do
      source = Note
      target = Note
      action = :created

      Gitlab::Event::Subscriptions::Note.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

    it "should subscribe user on exist note :note adds" do
      target = create :note
      source = :note
      action = :created

      Gitlab::Event::Subscriptions::Note.subscribe(@user, action, source, target)

      subscription = ::Event::Subscription.last
      subscription.should_not be_nil
      subscription.should be_persisted
    end

  end
end
