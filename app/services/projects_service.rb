class TransferError < StandardError; end

class ProjectsService < ::BaseService
  include Gitlab::ShellAdapter
  include Projects::BaseActions
  include Projects::HooksActions
  include Projects::UsersActions
  include Projects::TeamsActions
  include Projects::ServicesActions

  attr_accessor :project, :current_user, :params

  def initialize(user, project, params = {})
    @project, @current_user, @params = project, user, params.dup
  end

  def repository
    @repository_service ||= RepositoriesService.new(current_user, project, params)
  end

  def merge_request(merge_request = nil, target_project = nil)
    target_project ||= project
    @merge_request_service ||= MergeRequestsService.new(current_user, merge_request, params, project, target_project)
  end

  def milestone(milestone = nil)
    @milestone_service ||= MilestonesService.new(current_user, milestone, params, project)
  end

  def issue(issue = nil)
    @issue_service ||= IssuesService.new(current_user, issue, params, project)
  end

  def services(service = nil)
    @services_service ||= ServicesService.new(current_user, service, params)
  end

  def notes
    @notes_service ||= NotesService.new(current_user, project, params)
  end

  #
  # Projects
  #

  def create
    @params = project
    create_action
  end

  def update(role = :default)
    update_action(role)
  end

  def delete
    delete_action
  end

  def transfer(role = :default)
    namespace_id = params[:project].delete(:namespace_id)
    allowed_transfer = can?(current_user, :change_namespace, project) || role == :admin

    if allowed_transfer && namespace_id.present?
      if namespace_id.to_i != project.namespace_id
        # Transfer to someone namespace
        namespace = Namespace.find(namespace_id)
        transfer_action(namespace, role)
      end
    end
  end

  def fork
    fork_action
  end

  #
  # Hooks
  #

  def delete_hook(hook)
    remove_hook_action(hook)
  end

  def test_hook
    hook = project.hooks.find(params[:id])
    test_hook_action(hook)
  end

  #
  # Users
  #

  def add_membership
    add_membership_action
  end

  def update_membership(member)
    update_membership_action(member)
  end

  def remove_membership(member)
    remove_membership_action(member)
  end

  def import_memberships
    giver = Project.find(params[:source_project_id])
    import_memberships_action(giver)
  end

  def batch_update_memberships
    batch_update_memberships_action
  end

  def batch_remove_memberships
    batch_remove_memberships_action
  end
  #
  # Teams
  #

  def assign_team
    assign_team_action
  end

  def resign_team(team)
    resign_team_action(team)
  end

  #
  # Services
  #

  def create_service(role = :user)
    services.create_service_pattern(role)
  end

  def import_service_pattern(service, role = :user)
    services(service).import_service_pattern_in_project(project, role)
  end

  def update_service(service, role = :user)
    services(service).update_service_pattern(role)
  end
end
