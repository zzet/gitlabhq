module Projects
  class CreateBareRepository < Projects::Base
    # Create bare repository
    #
    # git init --bare /path/project
    # or
    # git clone --bare url /path/project
    #
    def perform
      project = context[:project]

      if project.import?
        project.import_start
        context[:create_repo_job_id] = RepositoryImportWorker.perform(id)
      else
        context[:create_repo_job_id] = GitlabShellWorker.perform_async(
          :add_repository,
          project.path_with_namespace
        )
      end
    end

    # While rollback job mb running
    # 1. Kill job if job not finished
    # 2. Undo job changes
    def rollback
      project = context[:project]

      if context[:create_repo_job_id].present?
        # Stop job, if running
        queue = Sidekiq::Queue.new("gitlab_shell")

        queue.each do |job|
          job.delete if job.jid == context[:create_repo_job_id]
        end
      end

      GitlabShellWorker.perform_async(
        :remove_repository,
        project.path_with_namespace
      )

      # MB
      # project.import_state = failed
    end
  end
end
