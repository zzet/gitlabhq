module Projects
  class BaseContext < ::BaseContext
    attr_accessor :project, :current_user, :params

    def initialize(user, project, params = {})
      @project, @current_user, @params = project, user, params.dup
    end

    def enable_git_protocol(project)
      Gitlab::AppLogger.info("#{project.owner.name} granted public access via git protocol for project \"#{project.name_with_namespace}\"")
      GitlabShellWorker.perform_async(
          :enable_git_protocol,
          project.path_with_namespace
      )
    end

    def disable_git_protocol(project)
      Gitlab::AppLogger.info("#{project.owner.name} removed public access via git protocol for project \"#{project.name_with_namespace}\"")
      GitlabShellWorker.perform_async(
          :disable_git_protocol,
          project.path_with_namespace
      )
    end
  end
end
