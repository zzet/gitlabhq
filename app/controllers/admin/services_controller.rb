class Admin::ServicesController < Admin::ApplicationController

  def index
    @service_modules = Service.descendants.map { |s| s.new }
    @services = Service.where(service_pattern_id: nil)
  end

  def show
    service
  end

  def new
    @service = Service.build_by_type(params[:key])
  end

  def create
    @service = Services::CreateContext.new(@current_user, params[:service]).execute(:admin)
    if @service.persisted?
      redirect_to :index
    else
      render :new
    end
  end

  def edit
    service
  end

  def update
    @service = Services::UpdateContext.new(@current_user, service, params[:service]).execute(:admin)
    if @service.errors.blank?
      redirect_to admin_service_path(@service.id)
    else
      render :edit
    end
  end

  def destroy
  end

  private

  def service
    @service ||= Service.find(params[:id])
  end
end
