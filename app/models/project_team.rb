class ProjectTeam
  attr_accessor :project

  def initialize(project)
    @project = project
  end

  # Shortcut to add users
  #
  # Use:
  #   @team << [@user, :master]
  #   @team << [@users, :master]
  #
  def << args
    users = args.first

    if users.respond_to?(:each)
      add_users(users, args.second)
    else
      add_user(users, args.second)
    end
  end

  def find(user_id)
    user = project.users.find_by(id: user_id)

    if group
      user ||= group.users.find_by(id: user_id)
    end

    user
  end

  def find_tm(user_id)
    tm = project.users_projects.find_by(user_id: user_id)

    # If user is not in project members
    # we should check for group membership
    if group && !tm
      tm = group.users_groups.find_by(user_id: user_id)
    end

    tm
  end

  def add_user(user, access)
    add_users_ids([user.id], access)
  end

  def add_users(users, access)
    add_users_ids(users.map(&:id), access)
  end

  def add_users_ids(user_ids, access)
    UsersProject.add_users_into_projects(
      [project.id],
      user_ids,
      access
    )
  end

  # Remove all users from project team
  def truncate
    UsersProject.truncate_team(project)
  end

  def users
    members
  end

  def members
    @members ||= fetch_members
  end

  def guests
    @guests ||= fetch_members(:guests)
  end

  def reporters
    @reporters ||= fetch_members(:reporters)
  end

  def developers
    @developers ||= fetch_members(:developers)
  end

  def masters
    @masters ||= fetch_members(:masters)
  end

  def owners
    @owners ||= fetch_members(:owners)
  end

  def import(source_project)
    target_project = project

    source_team = source_project.users_projects.to_a
    target_user_ids = target_project.users_projects.pluck(:user_id)

    source_team.reject! do |tm|
      # Skip if user already present in team
      target_user_ids.include?(tm.user_id)
    end

    source_team.map! do |tm|
      new_tm = tm.dup
      new_tm.id = nil
      new_tm.project_id = target_project.id
      new_tm
    end

    UsersProject.transaction do
      source_team.each do |tm|
        tm.save
      end
    end

    true
  rescue
    false
  end

  def guest?(user)
    max_tm_access(user.id) == Gitlab::Access::GUEST
  end

  def reporter?(user)
    max_tm_access(user.id) == Gitlab::Access::REPORTER
  end

  def developer?(user)
    max_tm_access(user.id) == Gitlab::Access::DEVELOPER
  end

  def master?(user)
    max_tm_access(user.id) == Gitlab::Access::MASTER
  end

  def max_tm_access(user_id)
    access = []
    access << project.users_projects.find_by(user_id: user_id).try(:access_field)

    if group
      access << group.users_groups.find_by(user_id: user_id).try(:access_field)
    end

    if teams.any?
      access << teams.map do |t|
        t.team_user_relationships.find_by(user_id: user_id).try(:access_field)
      end.flatten
    end

    access.compact.max
  end

  private

  def fetch_members(level = nil)
    User.where(id: (project_member_ids(level) + group_member_ids(level) + teams_member_ids(level)).uniq)
  end

  def group
    project.group
  end

  def teams
    (project_teams + group_teams).uniq
  end

  def project_teams
    project.teams.any? ? project.teams : []
  end

  def group_teams
    group ? project.group.teams : []
  end

  def project_member_ids(level = nil)
    project_members = project.users_projects
    project_members = project_members.send(level) if level
    project_members.pluck(:user_id)
  end

  def group_member_ids(level = nil)
    return [] unless group.present?
    group_members = group.users_groups
    group_members = group_members.send(level) if level
    group_members.pluck(:user_id)
  end

  def teams_member_ids(level = nil)
    group_teams_members   = group_teams.any? ? group.team_user_relationships : []
    project_teams_members = project_teams.any? ? project.team_user_relationships : []

    if level
      project_teams_members = project_teams_members.send(level) if project_teams_members.any?
      group_teams_members   = group_teams_members.send(level)   if group_teams_members.any?
    end

    project_teams_member_ids = project_teams_members.is_a?(Array) ? [] : project_teams_members.pluck(:user_id)
    group_teams_member_ids   = group_teams_members.is_a?(Array)   ? [] : group_teams_members.pluck(:user_id)

    user_ids = (project_teams_member_ids + group_teams_member_ids).uniq

    User.where(id: user_ids)
  end

  def project_access(member)

  end
end
