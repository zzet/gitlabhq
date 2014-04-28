class Admin::SettingsController < Admin::ApplicationController
  def show
    @email_domains = settings.email_domains
    @domain = settings.email_domains.build
  end

  def edit
    settings
  end

  def update
    @settings = GlobalSettings.first
    if @settings.update(params[:settings])
      redirect_to :index
    else
      render :edit
    end
  end

  private
  def settings
    @settings = begin
                  settings = GlobalSettings.first
                  settings = GlobalSettings.create unless settings.present?
                  settings
                end
  end
end
