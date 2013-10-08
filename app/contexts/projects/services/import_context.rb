module Projects
  module Services
    class ImportContext < Projects::Services::BaseContext
      def execute(role = :user)
        service_params = params
        service_configuration_params = service_params.delete(:configuration)

        if role != :admin
          service_params.delete(:avtive_state_event)
          service_params.delete(:publish_state_event)
        end

        @project_service = service.class.new
        @project_service.title = service.title
        @project_service.description = service.description
        @project_service.active_state = service.active_state
        @project_service.public_state = :unpublished

        if @project_service.save
          import_configuration(service, @project_service) if @project_service.respond_to?(:configuration)

          service.service_key_service_relationships.each do |kr|
            @project_service.service_key_service_relationships.create(service_key_id: kr.service_key_id, code_access_state: kr.code_access_state)
          end

          service.children << @project_service
          project.services << @project_service

          @project_service.state_event = service_params[:state_event]
          @project_service.save
        end

        @project_service
      end

      def import_configuration(source_service, target_service)
        attrs = source_service.configuration.attributes

        %w(id service_id service_type created_at updated_at).each do |key|
          attrs.delete(key)
        end

        config = @project_service.create_configuration(attrs)
      end
    end
  end
end
