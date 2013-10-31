class ProjectObserver < BaseObserver
  def after_create(project)
    project.update_column(:last_activity_at, project.created_at)

    return true if project.forked?

    if project.import?
      RepositoryImportWorker.perform_in(5.seconds, project.id)
    else
      GitlabShellWorker.perform_async(
        :add_repository,
        project.path_with_namespace
      )

      log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
    end

    if project.wiki_enabled?
      begin
        # force the creation of a wiki,
        GollumWiki.new(project, project.owner).wiki
      rescue GollumWiki::CouldNotCreateWikiError => ex
        # Prevent project observer crash
        # if failed to create wiki
        nil
      end
    end
  end

  def after_update(project)
    project.rename_repo if project.path_changed?

    if project.git_protocol_enabled_changed?
      if project.git_protocol_enabled
        log_info("#{project.owner.name} granted public access via git protocol for project \"#{project.name_with_namespace}\"")
        GitlabShellWorker.perform_async(
          :enable_git_protocol,
          project.path_with_namespace
        )
      else
        log_info("#{project.owner.name} removed public access via git protocol for project \"#{project.name_with_namespace}\"")
        GitlabShellWorker.perform_async(
          :disable_git_protocol,
          project.path_with_namespace
        )
      end
    end

    GitlabShellWorker.perform_async(
      :update_repository_head,
      project.path_with_namespace,
      project.default_branch
    ) if project.default_branch_changed?
  end

  def before_destroy(project)
    project.repository.expire_cache unless project.empty_repo?
  end

  def after_destroy(project)
    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace
    )

    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace + ".wiki"
    )

    project.satellite.destroy

    log_info("Project \"#{project.name}\" was removed")
  end
end
