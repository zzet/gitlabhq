module Services
  class CreateContext < ::BaseContext
    def execute(role = :user)
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
        @service.create_configuration(service_configuration_params) if @service.respond_to?(:configuration)

        if @service.user_params.any?
          @service_user = User.find_by_username(@service.user_params[:username])
          @service_user = User.create!(@service.user_params) if @service_user.blank?
          @service.create_service_user_relationship(user: @service_user)
        end
      end

      @service
    end
  end
end
