class GitlabShellWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(action, *arg)
    benchmark.gitlab_shell do
      gitlab_shell.send(action, *arg)
    end
    benchmark.finish
  end
end
