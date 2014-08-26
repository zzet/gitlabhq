module Projects::BaseActions
  private

  def create_action
    # get namespace id
    namespace_id = params.delete(:namespace_id)

    # check that user is allowed to set specified visibility_level
    unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
      params.delete(:visibility_level)
    end

    # Load default feature settings
    default_features = Gitlab.config.gitlab.default_projects_features

    default_opts = {
      issues_enabled:         default_features.issues,
      wiki_enabled:           default_features.wiki,
      snippets_enabled:       default_features.snippets,
      merge_requests_enabled: default_features.merge_requests,
      visibility_level:       default_features.visibility_level
    }.stringify_keys

    @project = Project.new(default_opts.merge(params))
    @project.issues_tracker = "redmine"
    @project.git_protocol_enabled = false

    # Parametrize path for project
    #
    # Ex.
    #  'GitLab HQ'.parameterize => "gitlab-hq"
    #
    @project.path = @project.name.dup.parameterize unless @project.path.present?


    if namespace_id
      # Find matching namespace and check if it allowed
      # for current user if namespace_id passed.
      if allowed_namespace?(current_user, namespace_id)
        @project.namespace_id = namespace_id
      else
        deny_namespace
        return @project
      end
    else
      # Set current user namespace if namespace_id is nil
      @project.namespace_id = current_user.namespace_id
    end

    @project.creator = current_user

    if @project.save
      unless @project.group
        @project.users_projects.create(
          project_access: UsersProject::MASTER,
          user: current_user
        )
      end

      @project.update_column(:last_activity_at, @project.created_at)

      if @project.import?
        @project.import_start
      else
        Resque.enqueue(GitlabShellWorker, :add_repository, @project.path_with_namespace)
      end

      if @project.wiki_enabled?
        begin
          # force the creation of a wiki,
          ProjectWiki.new(@project, @project.owner).wiki
        rescue ProjectWiki::CouldNotCreateWikiError => ex
          # Prevent project observer crash
          # if failed to create wiki
          nil
        end
      end

      if current_user.notification_setting && current_user.notification_setting.subscribe_if_owner
        SubscriptionService.subscribe(current_user, :all, @project, :all)
      end

      group = project.group
      if group
        group.teams.pluck(:id).each do |team_id|
          reindex_with_elastic(Team, team_id)
        end
      end

      ProjectsService.new(current_user, @project).import_service_pattern(git_checkpoint_service) if git_checkpoint_service
    end

    receive_delayed_notifications

    @project
  rescue
    @project.errors.add(:base, "Can't save project. Please try again later")
    @project
  end

  def update_action(role = :default)
    params[:project].delete(:namespace_id)
    # check that user is allowed to set specified visibility_level
    unless can?(current_user, :change_visibility_level, project) && Gitlab::VisibilityLevel.allowed_for?(current_user, params[:project][:visibility_level])
      params[:project].delete(:visibility_level)
    end

    new_branch = params[:project].delete(:default_branch)

    if project.repository.exists? && new_branch && new_branch != project.default_branch
      project.change_head(new_branch)
    end

    project.update(params[:project])

    if project.changes.include?("path")
      build_face_service = project.services.where(type: Service::BuildFace).first
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

  def delete_action
    project.destroy
    receive_delayed_notifications
  end

  def transfer_action(namespace, role = :default)
    Project.transaction do
      if allowed_transfer?(current_user, project, namespace)
        old_project_teams = project.teams
        old_project_teams_ids = old_project_teams.pluck(:id)

        old_group_teams = project.group.present? ? project.teams : Team.none
        old_group_teams_ids = old_group_teams.pluck(:id)

        old_teams_ids = (old_group_teams_ids + old_project_teams_ids).flatten

        if transfer_to(namespace)
          build_face_service = project.services.where(type: Service::BuildFace).first
          if build_face_service && build_face_service.enabled?
            build_face_service.notify_build_face("transfered")
          end

          teams_ids = old_teams_ids + project.teams.pluck(:id)
          teams_ids += project.group.teams.pluck(:id) if project.group.present?
          teams_ids = teams_ids.flatten.uniq

          teams_ids.each do |team_id|
            reindex_with_elastic(Team, team_id)
          end

          receive_delayed_notifications

          return true
        end
      else
        project.errors.add(:namespace, 'is invalid')
        return false
      end
    end
  end

  def fork_action
    from_project = project.dup
    from_project.name = project.name
    from_project.path = project.path
    from_project.namespace = current_user.namespace
    from_project.creator = current_user

    # If the from_project cannot save, we do not want to trigger the from_project destroy
    # as this can have the side effect of deleting a repo attached to an existing
    # from_project with the same name and namespace
    if from_project.valid?
      begin
        Project.transaction do
          #First save the DB entries as they can be rolled back if the repo fork fails
          from_project.build_forked_project_link(forked_to_project_id: from_project.id, forked_from_project_id: project.id)
          if from_project.save
            from_project.users_projects.create(project_access: UsersProject::MASTER, user: current_user)
          end
          #Now fork the repo
          unless gitlab_shell.fork_repository(project.path_with_namespace, from_project.namespace.path)
            raise "forking failed in gitlab-shell"
          end
          from_project.ensure_satellite_exists
          enable_git_protocol(from_project) if from_project.git_protocol_enabled
          ProjectsService.new(current_user, from_project).import_service_pattern(git_checkpoint_service) if git_checkpoint_service
        end
      rescue
        from_project.errors.add(:base, "Fork transaction failed.")
        from_project.destroy
      end
    else
      from_project.errors.add(:base, "Invalid fork destination")
    end

    from_project
  end

  private

  def deny_namespace
    @project.errors.add(:namespace, "is not valid")
  end

  def allowed_namespace?(user, namespace_id)
    namespace = Namespace.find_by(id: namespace_id)
    current_user.can?(:manage_namespace, namespace)
  end

  def allowed_transfer?(current_user, project, namespace)
    namespace &&
      can?(current_user, :change_namespace, project) &&
      namespace.id != project.namespace_id &&
      current_user.can?(:create_projects, namespace)
  end

  def transfer_to(new_namespace)
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

  def enable_git_protocol(project)
    Gitlab::AppLogger.info("#{project.owner.name} granted public access via git protocol for project \"#{project.name_with_namespace}\"")
    Resque.enqueue(GitlabShellWorker, :enable_git_protocol, project.path_with_namespace)
  end

  def disable_git_protocol(project)
    Gitlab::AppLogger.info("#{project.owner.name} removed public access via git protocol for project \"#{project.name_with_namespace}\"")
    Resque.enqueue(GitlabShellWorker, :disable_git_protocol, project.path_with_namespace)
  end

  def git_checkpoint_service
    @git_checkpoint_service ||= begin
                                  s = Service::GitCheckpoint.where(active_state: :active, public_state: :published)
                                  s.any? ? s.first : nil
                                rescue
                                  nil
                                end
  end
end
