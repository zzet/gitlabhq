class GroupsService < BaseService
  include Groups::BaseActions
  include Groups::UsersActions
  include Groups::TeamsActions

  attr_accessor :current_user, :group, :params

  def initialize(user, group, params = {})
    @current_user, @group, @params = user, group, params.dup
  end

  #
  # Groups
  #

  def create
    @params = group
    create_action
  end

  def delete
    delete_action
  end

  #
  # Users
  #

  def add_membership
    add_user_membership_action
  end

  def remove_membership(user)
    remove_user_membership_action(user)
  end

  def update_membership(user)
    update_user_membership_action(user)
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
end
