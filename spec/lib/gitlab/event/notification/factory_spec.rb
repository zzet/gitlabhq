require 'spec_helper'

describe Gitlab::Event::Notification::Factory do
  describe "Can create builders for events" do
    before do
      ActiveRecord::Base.observers.disable :all

      @user = create :user
      @project = create :project

      @event = create :event, { action: :created, source: @project, author: @user, data: "", target: @project }
    end

    it "should create default builder" do
      builder = Gitlab::Event::Notification::Factory.builder_for(@event)
      builder.should be_a_kind_of(Gitlab::Event::Notification::Builder::Default)
    end

    it "should find and create builder by source" do
      class Gitlab::Event::Notification::Builder::Project
      end

      builder = Gitlab::Event::Notification::Factory.builder_for(@event)
      builder.should be_a_kind_of(Gitlab::Event::Notification::Builder::Project)
    end

    it "should find and create builder by action and source" do
      class Gitlab::Event::Notification::Builder::ProjectCreated
      end

      builder = Gitlab::Event::Notification::Factory.builder_for(@event)
      builder.should be_a_kind_of(Gitlab::Event::Notification::Builder::ProjectCreated)
    end
  end

  describe "Can build and create notifications for events" do
    before do
      ActiveRecord::Base.observers.disable :all

      @user = create :user
      @project = create :project
      @data = GitPushService.new.sample_data(@project, @user).to_json

      @event = create :push_event, { author: @user, data: @data, target: @project }
      @subscription = create :push_subscription, { user: @user, target: @project }

      other_user = create :user
      @event_from_other_user = create :push_event, { author: other_user, data: @data, target: @project }

      @event
    end

    it "should not build notifications on own changes" do
      notifications = Gitlab::Event::Notification::Factory.build(@subscription, @event)
      notifications.should eq []
    end

    it "should build notifications on own changes if user enabled option 'Notify about own changes'" do
      @event.author.create_notification_setting(own_changes: true)

      notifications = Gitlab::Event::Notification::Factory.build(@subscription, @event)
      notifications.should have_at_least(1).items
    end

    it "should build notifications if event author is not user" do
      notifications = Gitlab::Event::Notification::Factory.build(@subscription, @event_from_other_user)
      notifications.should have_at_least(1).items
    end

    it "should create notifications for event" do
      @event.author.create_notification_setting(own_changes: true)

      notifications = Gitlab::Event::Notification::Factory.create_notifications(@event)
      @event.notifications.should have_at_least(1).items
    end
  end
end
