module Projects
  class UpdateContext < Projects::BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      params[:project].delete(:public) unless can?(current_user, :change_public_mode, project)
      new_branch = params[:project].delete(:default_branch)

      if project.repository.exists? && new_branch != project.repository.root_ref
        GitlabShellWorker.perform_async(
          :update_repository_head,
          project.path_with_namespace,
          new_branch
        )
      end

      project.update_attributes(params[:project], as: role)

      if project.changes.include?("path")
        build_face_servcie = project.services.where(type: Service::BuildFace).first
        if build_face_service && build_face_service.enabled?
          build_face_service.notify_build_face("updated")
        end
      end

      if project.git_protocol_enabled
        enable_git_protocol(project)
      else
        disable_git_protocol(project)
      end
    end
  end
end
