class Profiles::NotificationSettingsController < Profiles::ApplicationController
  respond_to :json

  def update
    notification_setting.update_attributes(params[:notification_settings])

    respond_with notification_setting
  end

  private

  def notification_setting
    @notification_setting ||= (@current_user.notification_setting || @current_user.create_notification_setting)
  end
end
