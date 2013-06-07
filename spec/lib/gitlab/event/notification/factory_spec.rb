require 'spec_helper'

describe Gitlab::Event::Notification::Factory do
  describe "Can create creators for events" do
    before do
      ActiveRecord::Base.observers.disable :all

      @user = create :user
      @project = create :project

      @event = create :event, { action: :created, source: @project, author: @user, data: "", target: @project }
    end

    it "should create default creator" do
      creator = Gitlab::Event::Notification::Factory.creator_for(@event)
      creator.should be_a_kind_of(Gitlab::Event::Notification::Creator::Default)
    end

    it "should find and create creator by source" do
      def_by_us = false
      unless defined?(Gitlab::Event::Notification::Creator::Project)
        def_by_us = true
        class Gitlab::Event::Notification::Creator::Project
        end
      end

      creator = Gitlab::Event::Notification::Factory.creator_for(@event)
      creator.should be_a_kind_of(Gitlab::Event::Notification::Creator::Project)

      Gitlab::Event::Notification::Creator.send(:remove_const, :Project) if def_by_us
    end

    it "should find and create creator by action and source" do
      def_by_us = false
      unless defined?(Gitlab::Event::Notification::Creator::ProjectCreated)
        def_by_us = true
        class Gitlab::Event::Notification::Creator::ProjectCreated
        end
      end

      creator = Gitlab::Event::Notification::Factory.creator_for(@event)
      creator.should be_a_kind_of(Gitlab::Event::Notification::Creator::ProjectCreated)

      Gitlab::Event::Notification::Creator.send(:remove_const, :ProjectCreated) if def_by_us
    end
  end

  describe "Can create and create notifications for events" do
    before do
      ActiveRecord::Base.observers.disable :all

      @user = create :user
      @project = create :project, { path: 'gitlabhq' }

      @data = GitPushService.new.sample_data(@project, @user).to_json

      @event = create :push_event, { author: @user, data: @data, target: @project }
      @subscription = create :push_subscription, { user: @user, target: @project }

      other_user = create :user
      @event_from_other_user = create :push_event, { author: other_user, data: @data, target: @project }

      @event
    end

    it "should not create notifications on own changes" do
      notifications = Gitlab::Event::Notification::Factory.create_notifications(@event)
      notifications.should eq []
    end

    it "should create notifications on own changes if user enabled option 'Notify about own changes'" do
      @event.author.create_notification_setting(own_changes: true)

      notifications = Gitlab::Event::Notification::Factory.create_notifications(@event)
      notifications.should have_at_least(1).items
    end

    it "should create notifications if event author is not user" do
      notifications = Gitlab::Event::Notification::Factory.create_notifications(@event_from_other_user)
      notifications.should have_at_least(1).items
    end

    it "should create notifications for event" do
      @event.author.create_notification_setting(own_changes: true)

      notifications = Gitlab::Event::Notification::Factory.create_notifications(@event)
      @event.notifications.should have_at_least(1).items
    end
  end
end
