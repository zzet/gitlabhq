module Projects
  class EnableGitProtocol < Projects::Base
    def perform
      project = context[:project]

      if project.git_protocol_enabled
        log_info("#{project.owner.name} granted public access via git protocol for project \"#{project.name_with_namespace}\"")

        context[:git_protocol_enable_job_id] = GitlabShellWorker.perform_async(
          :enable_git_protocol,
          project.path_with_namespace
        )
      end
    end

    def rollback
      project = context[:project]

      log_info("Rollback! Removed public access via git protocol for project \"#{project.name_with_namespace}\" granted by ...")

      stop_async_job("gitlab_shell", context[:git_protocol_enable_job_id])

      GitlabShellWorker.perform_async(
        :disable_git_protocol,
        project.path_with_namespace
      )
    end
  end
end
