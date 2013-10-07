# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::Services::ApplicationController < Admin::ApplicationController
  before_filter :service

  def service
    @service ||= Service.find(params[:service_id])
  end
end
