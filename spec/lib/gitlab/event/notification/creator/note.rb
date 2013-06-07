require 'spec_helper'

describe Gitlab::Event::Notification::Creator::Note do
  before do
    ActiveRecord::Base.observers.disable :all

    @user = create :user, { email: "dmitriy.zaporozhets@gmail.com" }
    @project = create :project, path: 'gitlabhq'

    @project.team << [@user, 40]

    @note = create :note_on_commit, { project: @project }
  end

  it "should build notifications for commit author if commit commented by other user" do
    user = create :user
    event = create :event, { action: :commented, source: @note, author: user, data: @note.to_json, target: @project }

    Gitlab::Event::Notification::Factory.create_notifications(event)

    notification = @user.notifications.find_by_event_id event.id
    notification.should_not be_nil
  end
end
