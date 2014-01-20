class Admin::ServicesController < Admin::ApplicationController

  def index
    @service_modules = Service.implement_services.map { |s| s.new }
    @services = Service.where(service_pattern_id: nil)
  end

  def show
    service
    @projects = service.child_projects.includes(:namespace).order("namespaces.path, projects.name ASC")
  end

  def new
    @service = Service.build_by_type(params[:key])
  end

  def create
    @service = ::ServicesService.new(@current_user, params[:service]).create_service_pattern(:admin)
    if @service.persisted?
      redirect_to admin_services_path
    else
      render :new
    end
  end

  def edit
    service
  end

  def update
    @service = ::ServicesService.new(@current_user, service, params[:service]).update_service_pattern(:admin)
    if @service.errors.blank?
      redirect_to admin_service_path(@service.id)
    else
      render :edit
    end
  end

  def destroy
    if ::ServicesService.new(@current_user, service).remove_service_pattern(:admin)
      redirect_to admin_services_path
    else
      render :edit
    end
  end

  private

  def service
    @service ||= Service.find(params[:id])
  end
end
