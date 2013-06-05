require 'spec_helper'

describe Gitlab::Event::Notification::Creator::UsersProject do
  before do
    ActiveRecord::Base.observers.disable :all

    @user = create :user
    @project = create :project
    @data = GitPushService.new.sample_data(@project, @user).to_json

    @event = create :push_event, { author: @user, data: @data, target: @project }
    @subscription = create :push_subscription, { user: @user, target: @project }

    other_user = create :user
    @event_from_other_user = create :push_event, { author: other_user, data: @data, target: @project }
  end

  it "should not allow to create dublicate notifications" do
  end
end
