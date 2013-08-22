module Projects
  class UpdateContext < Projects::BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      params[:project].delete(:public) unless can?(current_user, :change_public_mode, project)
      project.update_attributes(params[:project], as: role)

      if project.changes.include?("path")
        if project.build_face_service && project.build_face_service.enabled?
          project.build_face_service.notify_build_face("updated")
        end
      end
    end
  end
end
