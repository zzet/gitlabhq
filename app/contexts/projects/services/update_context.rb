module Projects
  module Services
    class UpdateContext < Projects::Services::BaseContext
      def execute(role = :user)
        service_params = params
        service_configuration_params = service_params.delete(:configuration)

        if role == :admin
          service_params.delete(:state_event)
        else
          service_params.delete(:active_state_event)
          service_params.delete(:publish_state_event)
        end

        if service.update_attributes(service_params)
          service.configuration.update_attributes(service_configuration_params)
        end

        service
      end
    end
  end
end
