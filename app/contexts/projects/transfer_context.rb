module Projects
  class TransferError < StandardError; end

  class TransferContext < Projects::BaseContext
    include Gitlab::ShellAdapter

    attr_accessor :project, :current_user, :namespace

    def initialize(user, project, namespace)
      @project, @current_user, @namespace = project, user, namespace
    end

    def execute(role = :default)
      Project.transaction do
        allowed_transfer = can?(current_user, :change_namespace, project) || role == :admin

        if allowed_transfer && (namespace != project.namespace)
          old_namespace = project.namespace

            if project.build_face_service && project.build_face_service.enabled?
              project.build_face_service.notify_build_face("transfered")
            end

          if transfer_to(namespace)
            receive_delayed_notifications
          end
        end
      end
    end

    def transfer_to(new_namespace)
      begin
        old_path = project.path_with_namespace
        new_path = File.join(new_namespace.try(:path) || '', project.path)

        if Project.where(path: project.path, namespace_id: new_namespace.try(:id)).present?
          raise Projects::TransferError.new("Project with same path in target namespace already exists")
        end

        project.namespace = new_namespace

        if project.save
          # Move main repository
          unless gitlab_shell.mv_repository(old_path, new_path)
            raise Projects::TransferError.new('Cannot move project')
          end

          # Move wiki repo also if present
          gitlab_shell.mv_repository("#{old_path}.wiki", "#{new_path}.wiki")

          # create satellite repo
          project.ensure_satellite_exists

          # clear project cached events
          project.reset_events_cache

          return true
        else
          raise TransferError.new("Cannot update project namespace")
        end
      rescue Projects::TransferError => ex
        project.reload
        project.errors.add(:namespace_id, ex.message)
        false
      end
    end
  end
end
