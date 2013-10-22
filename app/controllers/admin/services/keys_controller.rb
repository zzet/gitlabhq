class Admin::Services::KeysController < Admin::Services::ApplicationController
  def index
    @enabled_keys = @service.service_keys.all
    @available_keys = available_keys - @enabled_keys
  end

  def show
    @key = @service.service_keys.find(params[:id])
  end

  def new
    @key = @service.service_keys.new
  end

  def create
    @key = ServiceKey.new(params[:service_key])

    if @key.valid? && @service.service_keys << @key
      redirect_to admin_service_keys_path(@service.id)
    else
      render "new"
    end
  end

  def destroy
    @key = @service.service_keys.find(params[:id])
    @key.destroy

    respond_to do |format|
      format.html { redirect_to admin_service_keys_url }
      format.js { render nothing: true }
    end
  end

  def enable
    key = available_keys.find(params[:id])
    service.service_keys << key
    service.children.each do |srv|
      srv.service_keys << key
    end

    redirect_to admin_service_keys_path(@service)
  end

  def disable
    services = @service.children.pluck(:id)
    services << @service.id
    ServiceKeyServiceRelationship.where(service_key_id: params[:id], service_id: services).destroy_all

    redirect_to admin_service_keys_path(@service)
  end

  protected

  def available_keys
    @available_keys ||= ServiceKey.scoped
  end
end
