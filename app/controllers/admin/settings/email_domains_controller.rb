class Admin::Settings::EmailDomainsController < Admin::Settings::ApplicationController
  def index
    @email_domains = settings.email_domains
    @domain ||= settings.email_domains.build
  end

  def new
    @domain = settings.email_domains.build
  end

  def create
    @email_domains = settings.email_domains
    @domain = settings.email_domains.new(params[:global_settings_email_domains])
    if @domain.save
      redirect_to admin_settings_path
    else
      render :index
    end
  end

  def edit
    @domain = settings.email_domains.find(params[:id])
  end

  def update
    @domain = settings.email_domains.find(params[:id])
    if @domain.update(params[:global_settings_email_domains])
      redirect_to admin_settings_path
    else
      render :index
    end
  end

  def destroy
    settings.email_domains.find(params[:id]).destroy
    redirect_to admin_settings_path
  end
end
