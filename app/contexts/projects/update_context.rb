module Projects
  class UpdateContext < Projects::BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      # check that user is allowed to set specified visibility_level
      unless can?(current_user, :change_visibility_level, project) && Gitlab::VisibilityLevel.allowed_for?(current_user, params[:project][:visibility_level])
        params[:project].delete(:visibility_level)
      end

      new_branch = params[:project].delete(:default_branch)

      if project.repository.exists? && new_branch && new_branch != project.default_branch
        project.change_head(new_branch)
      end

      project.update_attributes(params[:project], as: role)

      if project.changes.include?("path")
        build_face_servcie = project.services.where(type: Service::BuildFace).first
        if build_face_service && build_face_service.enabled?
          build_face_service.notify_build_face("updated")
        end
      end
    end
  end
end
