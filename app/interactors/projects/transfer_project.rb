module Projects
  class TransferProject < Projects::Base
    def setup
      super

      context.fail!(message: "User not exist") if context[:user].blank?

      unless allowed_transfer?(context[:user], context[:project], context[:namespace])
        context.fail!(message: "Namespace is invalid")
      end
    end

    def perform
      project = context[:project]
      context[:old_namespace] = project.namespace_id

      old_teams_ids = project_teams_ids(project)

      if transfer(project: project, new_namespace: namespace)
        update_teams_elasticsearch_index(old_teams_ids, project)

        receive_delayed_notifications
      end
    end

    def rollback
      project = context[:project].reload

      old_teams_ids = project_teams_ids(project)

      if transfer(project: project, new_namespace: context[:old_namespace])
        update_teams_elasticsearch_index(old_teams_ids, project)

        receive_delayed_notifications
      end
    end

    private

    def allowed_transfer?(user, project, namespace)
      namespace && namespace.id != project.namespace_id &&
        can?(current_user, :change_namespace, project) &&
        can?(current_user, :create_projects, namespace)
    end

    def transfer(proejct: project, new_namespace: namespece)
      begin
        old_path = project.path_with_namespace
        new_path = File.join(new_namespace.try(:path) || '', project.path)

        if Project.where(path: project.path, namespace_id: new_namespace.try(:id)).present?
          raise TransferError.new("Project with same path in target namespace already exists")
        end

        # Remove old satellite
        project.satellite.destroy

        # Apply new namespace id
        project.namespace = new_namespace
        project.save!

        # Move main repository
        unless gitlab_shell.mv_repository(old_path, new_path)
          raise TransferError.new('Cannot move project')
        end

        # Move wiki repo also if present
        gitlab_shell.mv_repository("#{old_path}.wiki", "#{new_path}.wiki")

        # Create a new satellite (reload project from DB)
        Project.find(project.id).ensure_satellite_exists

        # clear project cached events
        project.reset_events_cache

        return true
      rescue TransferError => ex
        project.reload
        project.errors.add(:namespace_id, ex.message)
        false
      end
    end

    def project_teams_ids(project)
      old_project_teams = project.teams
      old_project_teams_ids = old_project_teams.pluck(:id)

      old_group_teams = project.group.present? ? project.teams : Team.none
      old_group_teams_ids = old_group_teams.pluck(:id)

      (old_group_teams_ids + old_project_teams_ids).flatten
    end

    def notify_build_face_service(project)
      build_face_service = project.services.where(type: Service::BuildFace).first
      if build_face_service && build_face_service.enabled?
        build_face_service.notify_build_face("transfered")
      end
    end

    def update_teams_elasticsearch_index(old_teams_ids, project)
      teams_ids = old_teams_ids + project.teams.pluck(:id)
      teams_ids += project.group.teams.pluck(:id) if project.group.present?
      teams_ids = teams_ids.flatten.uniq

      teams_ids.each do |team_id|
        reindex_with_elastic(Team, team_id)
      end


    end
  end
end
