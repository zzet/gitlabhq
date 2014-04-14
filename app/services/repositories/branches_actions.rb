module Repositories::BranchesActions
  private

  def protect_branch_action(branch)
    @project.protected_branches.create(name: branch)
  end

  def unprotect_branch_action(branch)
    br = @project.protected_branches.find_by(name: branch)
    br.destroy

    receive_delayed_notifications
  end

  def create_branch_action(branch, ref)
    project.repository.add_branch(branch, ref)
    new_branch = project.repository.find_branch(branch)
    if new_branch
      oldrev = "0000000000000000000000000000000000000000"
      newrev = new_branch.target
      ref = "refs/heads/" << new_branch.name

      GitPushService.new(current_user, project, oldrev, newrev, ref).execute
    end
  end

  def delete_branch_action(branch)
    branch = project.repository.find_branch(branch)
    if branch && project.repository.rm_branch(branch.name)
      oldrev = branch.target
      newrev = "0000000000000000000000000000000000000000"
      ref = "refs/heads/" << branch.name

      GitPushService.new(current_user, project, oldrev, newrev, ref).execute

      receive_delayed_notifications
    end
  end
end
