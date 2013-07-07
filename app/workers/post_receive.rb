class PostReceive
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker
  include Gitlab::Identifier

  sidekiq_options queue: :post_receive

  def perform(repo_path, oldrev, newrev, ref, identifier)

    if repo_path.start_with?(Gitlab.config.gitlab_shell.repos_path.to_s)
      repo_path.gsub!(Gitlab.config.gitlab_shell.repos_path.to_s, "")
    else
      log("Check gitlab.yml config for correct gitlab_shell.repos_path variable. \"#{Gitlab.config.gitlab_shell.repos_path}\" does not match \"#{repo_path}\"")
    end

    repo_path.gsub!(/.git$/, "")
    repo_path.gsub!(/^\//, "")

    project = Project.find_with_namespace(repo_path)

    if project.nil?
      log("Triggered hook for non-existing project with full path \"#{repo_path} \"")
      return false
    end

    user = identify(identifier, project, newrev)

    unless user
      log("Triggered hook for non-existing user \"#{identifier} \"")
      return false
    end

    benchmark.execute_git_push do
      GitPushService.new.execute(project, user, oldrev, newrev, ref)
    end
    benchmark.finish
  end

  def log(message)
    benchmark.log_data do
      Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
    end
    benchmark.finish
  end
end
