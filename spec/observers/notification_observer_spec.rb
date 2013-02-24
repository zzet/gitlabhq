require 'spec_helper'

describe NotificationObserver do
  subject { NotificationObserver.instance }

  before do
    @user = create :user
    Gitlab::Event::Action.current_user = @user
    Gitlab::Event::Subscription.subscribe @user, :all, @user, :all
  end

  it "should send email with user update" do
    @user.name = "#{@user.name}_updated"
    @user.save
  end

  context 'when user updated' do
    it 'should send email with information' do
      Gitlab::Event::Notifications.should_receive(:process_notification)
      @user.name = "#{@user.name}_updated"
      @user.save
    end
  end
end
