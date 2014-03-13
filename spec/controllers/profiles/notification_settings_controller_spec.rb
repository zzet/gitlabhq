require 'spec_helper'

describe Profiles::NotificationSettingsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user)
  end

  describe "#update" do
    render_views

    it "should update settings" do
      patch :update, { notification_settings: {
        own_changes: true,
        system_notifications: true,
      }, format: :json}

      user.notification_setting.system_notifications.should be_true
    end
  end
end
