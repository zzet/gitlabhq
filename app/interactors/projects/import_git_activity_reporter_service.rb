module Projects
  class ImportGitCheckpointService < Projects::Base

    def perform
      project = context[:project]

      if git_checkpoint_service
        ProjectsService.new(current_user, project).import_service_pattern(git_checkpoint_service)
      end
    end

    def rollback

    end
  end
end
