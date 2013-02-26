require "spec_helper"

describe EventNotificationMailer do
  before do
    @user = create :user
    Gitlab::Event::Action.current_user = @user
    SubscriptionService.subscribe(@user, :all, @user, :all)
    SubscriptionService.subscribe(@user, :all, :group, :all)
    SubscriptionService.subscribe(@user, :all, :project, :all)
    SubscriptionService.subscribe(@user, :all, :user_team, :all)

    @project = create :project, creator: @user
    @group = create :group, owner: @user
    @user_team = create :user_team, owner: @user
  end

  it "should send email about create project" do
    project = create :project
    ActionMailer::Base.deliveries.should_not be_blank
  end
end
