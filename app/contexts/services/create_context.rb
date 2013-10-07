class Services::CreateContext < ::BaseContext
  def execute(role = :user)
    service_params = params
    service_type = service_params.delete(:service_type)
    service_configuration_params = service_params.delete(:configuration)

    if role == :admin
      service_params.delete(:state_event)
    else
      service_params.delete(:avtive_state_event)
      service_params.delete(:publish_state_event)
    end

    @service = Service.build_by_type(service_type)

    if @service.save
      @service.create_configuration(service_configuration_params)
    end

    @service
  end
end
