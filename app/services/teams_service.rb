class TeamsService < BaseService
  include Teams::BaseActions
  include Teams::UsersActions
  include Teams::GroupsActions
  include Teams::ProjectsActions

  attr_accessor :current_user, :team, :params

  def initialize(user, team, params = {})
    @current_user, @team, @params = user, team, params.dup
  end

  #
  # Base
  #

  def create
    @params = team
    create_action
  end

  def delete
    remove_action
  end

  #
  # Groups
  #

  def assign_on_groups(groups = nil)
    if groups.nil?
      group_ids = params[:group_ids].respond_to?(:each) ? params[:group_ids] : params[:group_ids].split(',')
      groups = Group.where(id: group_ids)
    end
    assign_on_groups_action(groups)
  end

  def resign_from_groups(groups)
    resign_from_groups_action(groups)
  end

  #
  # Projects
  #

  def assign_on_projects(projects = nil)
    if projects.nil?
      project_ids = params[:project_ids].respond_to?(:each) ? params[:project_ids] : params[:project_ids].split(',')
      projects = Project.where(id: project_ids)
    end
    assign_on_projects_action(projects)
  end

  def resign_from_projects(projects)
    resign_from_projects_action(projects)
  end

  #
  # Users
  #

  def add_memberships
    unless params[:user_ids].blank?
      user_ids = params[:user_ids].respond_to?(:each) ? params[:user_ids] : params[:user_ids].split(',')
      users = User.where(id: user_ids)
      access = params[:team_access]
      add_memberships_action(users, access)
    end
  end

  def delete_membership(member)
    remove_membership_action(member)
  end

  def update_memberships(members, access = nil)
    access = params[:team_access] if access.nil?
    update_memberships_action(members, access)
  end
end
