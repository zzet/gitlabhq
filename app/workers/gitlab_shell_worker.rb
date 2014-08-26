class GitlabShellWorker
  include Gitlab::ShellAdapter

  @queue = :gitlab_shell

  def perform(action, *arg)
    gitlab_shell.send(action, *arg)
  end

  def self.perform(action, *arg)
    GitlabShellWorker.new.perform(action, *arg)
  end
end
