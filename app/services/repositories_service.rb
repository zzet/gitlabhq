class RepositoriesService < ProjectsService
  include Repositories::BranchesActions
  include Repositories::FilesActions
  include Repositories::TagsActions

  attr_accessor :project, :current_user, :params

  #
  # Branches
  #

  def initialize(user, project, params = {})
    @project, @current_user, @params = project, user, params.dup
  end

  def create_branch(branch, ref)
    create_branch_action(branch, ref)
  end

  def delete_branch(branch)
    delete_branch_action(branch)
  end

  def protect_branch(branch)
    protect_branch_action(branch)
  end

  def unprotect_branch(branch)
    unprotect_branch_action(branch)
  end

  #
  # Tags
  #

  def create_tag(tag, ref)
    create_tag_action(tag, ref)
  end

  def delete_tag(tag)
    delete_tag_action(tag)
  end

  #
  # Files
  #

  def create_file(ref, path)
    create_file_action(ref, path)
  end

  def delete_file(ref, path)
    delete_file_action(ref, path)
  end

  def update_file(ref, path)
    update_file_action(ref, path)
  end
end
