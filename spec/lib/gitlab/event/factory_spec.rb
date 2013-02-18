require 'spec_helper'

describe Gitlab::Event::Factory do
  it "should build unsaved events on action" do
    Gitlab::Event::Factory.should respond_to :build
  end

  it "should create events from action" do
    Gitlab::Event::Factory.should respond_to :create_events
  end

  #
  # Issue events
  #

  describe "Issue events" do
    before do
      @user = create :user

      Gitlab::Event::Notifications.current_user = @user
      ActiveRecord::Base.observers.disable :all
      Issue.observers.enable :activity_observer

      @project = create :project, creator: @user
    end

    it "should build unsaved events on :created action for Issue" do
      @issue = create(:issue, project: @project)

      @action = 'gitlab.created.issue'
      @data = {source: @issue, user: @user, data: @issue}
      @events = Gitlab::Event::Factory.build(@action, @data)

      @events.should be_kind_of Array
      @events.should_not be_blank

      @events.each do |event|
        event.should_not be_persisted
      end
    end

    it "should build events from hash" do
      @issue = create(:issue, project: @project)
      #@old_events = Event.with_source(@issue)
      Event.with_source(@issue).destroy_all

      @action = 'gitlab.created.issue'
      @data = {source: @issue, user: @user, data: @issue}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@issue)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count
    end

    it "should build events from hash" do
      @issue = create(:issue, project: @project)
      @issue.title = "#{@issue.title}_updated"
      @issue.save

      Event.with_source(@issue).destroy_all

      @action = 'gitlab.updated.issue'
      @data = {source: @issue, user: @user, data: @issue}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@issue)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update Issue.
    end
  end
end
