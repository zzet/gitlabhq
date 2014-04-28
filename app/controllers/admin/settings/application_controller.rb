# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::Settings::ApplicationController < Admin::ApplicationController
  before_filter :settings

  def settings
    @global_settings ||= GlobalSettings.first
  end
end
