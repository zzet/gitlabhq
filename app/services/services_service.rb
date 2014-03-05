class ServicesService < BaseService
  attr_accessor :service, :current_user, :params

  def initialize(user, service, params = {})
    @service, @current_user, @params = service, user, params.dup
  end

  def create_service_pattern(role = :user)
    params = @service if params.blank?
    service_params = params
    service_type = service_params.delete(:service_type)
    service_configuration_params = service_params.delete(:configuration)

    if role == :admin
      service_params.delete(:state_event)
    else
      service_params.delete(:active_state_event)
      service_params.delete(:public_state_event)
    end

    @service = Service.build_by_type(service_type, service_params)

    if @service.save
      @service.configuration.update_attributes(service_configuration_params) if @service.respond_to?(:configuration)

      if @service.user_params.any?
        @service_user = User.find_by(username: @service.user_params[:username])
        @service_user = User.create!(@service.user_params) if @service_user.blank?
        @service.create_service_user_relationship(user: @service_user)
      end
    end

    @service
  end

  def remove_service_pattern(role = :user)
    begin
      if role == :user && service.children.any?
        return false
      end

      Service.transaction do
        service.children.each do |children|
          children.destroy
        end

        service.destroy
      end
    rescue
      return false
    end

    true
  end

  def update_service_pattern(role = :user)
    service_params = params
    service_configuration_params = service_params.delete(:configuration)

    if role == :admin
      service_params.delete(:state_event)
    else
      service_params.delete(:active_state_event)
      service_params.delete(:publish_state_event)
    end

    if service.update_attributes(service_params)
      service.configuration.update_attributes(service_configuration_params) if service.respond_to?(:configuration)
    end

    service
  end

  def import_service_pattern_in_project(project, role = :user)
    service_params = params
    service_params.delete(:configuration)

    if role != :admin
      service_params.delete(:active_state_event)
      service_params.delete(:publish_state_event)
    end

    service_state = service_params.delete(:state_event) || :enable

    project_service = service.class.new
    project_service.title = service.title
    project_service.description = service.description
    project_service.active_state = service.active_state
    project_service.public_state = :unpublished

    if project_service.save
      import_service_configuration(service, project_service) if project_service.respond_to?(:configuration)

      service.service_key_service_relationships.each do |kr|
        project_service.service_key_service_relationships.create(service_key: kr.service_key, code_access_state: kr.code_access_state)
      end

      service.children << project_service
      project.services << project_service

      project_service.state_event = service_state
      project_service.save
    end

    project_service
  end

  private

  def import_service_configuration(source_service, target_service)
    attrs = source_service.configuration.attributes

    %w(id service_id service_type created_at updated_at).each do |key|
      attrs.delete(key)
    end

    target_service.build_configuration(attrs)
    target_service.configuration.save
  end
end
