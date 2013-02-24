require 'spec_helper'

describe "Gitlab::Event::Notifications" do
    describe "User subscriptions" do
    before do
      @user = create :user

      Gitlab::Event::Action.current_user = @user
      ActiveRecord::Base.observers.disable :all
      #User.observers.enable :activity_observer
    end

    it "should crate notification for user self updates" do
      Event.with_source(@user).destroy_all
      SubscriptionService.subscribe(@user, :all, @user, :all)

      @user.name = "#{@user.name}_updated"
      @user.save

      @action = 'gitlab.updated.user'
      @data = {source: @user, user: @user, data: @user}

      Gitlab::Event::Factory.create_events(@action, @data)

      @events = Event.with_source(@user)

      @events.each do |event|
        Gitlab::Event::Notifications.create_notifications(event)
      end

      @user_notificatons = @user.notifications

      @user_notificatons.should_not be_blank
    end

    it "should create one notification for user self updates" do
      Event.with_source(@user).destroy_all

      # user was subscribed on profile updates
      SubscriptionService.subscribe(@user, :updated, @user, @user)
      # and subscribe on all updates with all related changes
      SubscriptionService.subscribe(@user, :all, @user, :all)

      @user.name = "#{@user.name}_updated"
      @user.save

      @action = 'gitlab.updated.user'
      @data = {source: @user, user: @user, data: @user}

      Gitlab::Event::Factory.create_events(@action, @data)

      @events = Event.with_source(@user)

      @events.each do |event|
        Gitlab::Event::Notifications.create_notifications(event)
      end

      @user_notificatons = @user.notifications

      @user_notificatons.should_not be_blank
      @user_notificatons.count.should == 1

      @key = create :key, user: @user

      @action = 'gitlab.created.key'
      @data = {source: @key, user: @user, data: @key}

      Gitlab::Event::Factory.create_events(@action, @data)

      @key_events = Event.with_source(@key)

      @key_events.each do |event|
        Gitlab::Event::Notifications.create_notifications(event)
      end

      @user.reload

      @tmp = @user.notifications
      @new_user_notifications = @tmp - @user_notificatons

      @new_user_notifications.should_not be_blank
      @new_user_notifications.count.should == 1
    end

  end
end
