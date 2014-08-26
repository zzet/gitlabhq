class PostReceive
  include Gitlab::Identifier

  @queue = :post_receive

  def self.perform(repo_path, oldrev, newrev, ref, identifier)

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

    GitPushService.new(user, project, oldrev, newrev, ref).execute
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end
