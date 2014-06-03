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
    repository = project.repository
    repository.add_branch(branch, ref)
    new_branch = repository.find_branch(branch)
    if new_branch
      oldrev = "0000000000000000000000000000000000000000"
      newrev = new_branch.target
      ref = "refs/heads/" << new_branch.name

      GitPushService.new(current_user, project, oldrev, newrev, ref).execute
    end
    new_branch
  end

  def delete_branch_action(branch)
    repository = project.repository
    branch = repository.find_branch(branch)

    # No such branch
    unless branch
      return error('No such branch')
    end

    if branch.name == repository.root_ref
      return error('Cannot remove HEAD branch')
    end

    # Dont allow remove of protected branch
    if project.protected_branch?(branch.name)
      return error('Protected branch cant be removed')
    end

    # Dont allow user to remove branch if he is not allowed to push
    unless current_user.can?(:push_code, project)
      return error('You don\'t have push access to repo')
    end

    if branch && repository.rm_branch(branch.name)
      oldrev = branch.target
      newrev = "0000000000000000000000000000000000000000"
      ref = "refs/heads/" << branch.name

      GitPushService.new(current_user, project, oldrev, newrev, ref).execute

      receive_delayed_notifications

      return success("Branch '#{branch}' was removed")
    end
  end
end
