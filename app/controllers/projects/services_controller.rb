class Projects::ServicesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    @project_services = @project.services

    used_patters = @project_services.map {|ps| ps.pattern.id }.compact

    @services = Service.public_list
    @services = @services.where("id not in (:patterns)", patterns: used_patters) if used_patters.any?
    @services = @services + @project_services
  end

  def edit
    service
  end

  def update
    @service = if service.pattern.present?
                 Projects::Services::UpdateContext.new(current_user, @project, service, params[:service]).execute
               else
                 Projects::Services::ImportContext.new(current_user, @project, service, params[:service]).execute
               end

    if @service.valid?
      redirect_to edit_project_service_path(@project.path_with_namespace, @service.id)
    else
      render 'edit'
    end
  end

  def test
    data = GitPushService.new.sample_data(project, current_user)

    service.execute(data)

    redirect_to :back
  end

  private

  def service
    @service ||= Service.find(params[:id])
  end
end
