class RepositoryImportWorker
  include Gitlab::ShellAdapter

  @queue = :gitlab_shell

  def self.perform(project_id)
    RepositoryImportWorker.new.perform(project_id)
  end

  def perform(project_id)
    project = Project.find(project_id)
    result = gitlab_shell.send(:import_repository,
                               project.path_with_namespace,
                               project.import_url)

    if result
      project.import_finish
      project.save
      project.satellite.create unless project.satellite.exists?
    else
      project.import_fail
    end
  end
end
