# == Schema Information
#
# Table name: teams
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  path        :string(255)
#  description :text
#  creator_id  :integer
#  public      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Team < ActiveRecord::Base
  include Gitlab::Access
  include Watchable
  include TeamsSearch

  attr_accessible :name, :description, :creator_id, :path, :public

  belongs_to :creator, class_name: User

  has_many :team_project_relationships, dependent: :destroy
  has_many :team_user_relationships,    dependent: :destroy
  has_many :team_group_relationships,   dependent: :destroy

  has_many :projects,         through: :team_project_relationships
  has_many :groups,           through: :team_group_relationships
  has_many :accessed_projects,through: :groups, source: :projects
  has_many :members,          -> { where({ users: { state: :active } })}, through: :team_user_relationships, source: :user

  has_many :guests,           -> { where({ users: { state: :active },
                                           team_user_relationships: { team_access: Team::GUEST } })},
                              through: :team_user_relationships, source: :user

  has_many :reporters,        -> { where({ users: { state: :active },
                                           team_user_relationships: { team_access: Team::REPORTER } })},
                              through: :team_user_relationships, source: :user

  has_many :developers,       -> { where({ users: { state: :active },
                                           team_user_relationships: { team_access: Team::DEVELOPER } })},
                              through: :team_user_relationships, source: :user

  has_many :masters,          -> { where({ users: { state: :active },
                                           team_user_relationships: { team_access: [Team::MASTER, Team::OWNER] } })},
                              through: :team_user_relationships, source: :user

  has_many :owners,           -> { where({ users: { state: :active },
                                           team_user_relationships: { team_access: Team::OWNER } })},
                              through: :team_user_relationships, source: :user

  validates :creator, presence: true
  validates :name,    presence: true, uniqueness: true,
                      length: { within: 0..255 },
                      format: { with: Gitlab::Regex.name_regex,
                                message: "only letters, digits, spaces & '_' '-' '.' allowed." }
  validates :path,    presence: true, uniqueness: true, length: { within: 1..255 },
                      format: { with: Gitlab::Regex.path_regex,
                                message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :description, length: { within: 0..255 }

  watch do
    source watchable_name do
      title 'Team'
      description 'Notify about team update/destroy, adding groups, projects or users.'
      from :create,  to: :created
      from :update,  to: :updated
      from :destroy, to: :deleted
      # Mass actions
      from :groups_add,       to: :groups_added
      from :projects_add,     to: :projects_added
      from :memberships_add,  to: :members_added
    end

    source :team_user_relationship do
      title 'User'
      description 'Notify about user join/left team.'
      before do: -> { @target = @source.team }
      from :create,  to: :joined
      from :update,  to: :updated
      from :destroy, to: :left
    end

    source :team_project_relationship do
      title 'Project'
      description 'Notify about project assign/resign.'
      before do: -> { @target = @source.team }
      from :create,  to: :assigned
      from :update,  to: :updated
      from :destroy, to: :resigned
    end

    source :team_group_relationship do
      title 'Group'
      description 'Notify about group assign/resign.'
      before do: -> { @target = @source.team }
      from :create,  to: :assigned
      from :update,  to: :updated
      from :destroy, to: :resigned
    end
  end

  scope :created_by,      ->(user)    { where(creator_id: user) }
  scope :with_member,     ->(user)    { joins(:team_user_relationships).where(team_user_relationships: { user_id: user.id }) }

  scope :with_project,    ->(project) { joins(:team_project_relationships).where(team_project_relationships: { project_id: project })}
  scope :without_project, ->(project) { where.not(id: (a = with_project(project); a.blank? ? 0 : a))}

  scope :with_group,      ->(group)   { joins(:team_group_relationships).where(team_group_relationships: { group_id: group })}
  scope :without_group,   ->(group)   { where.not(id: (a = with_group(group); a.blank? ? 0 : a))}

  delegate :name, to: :creator, allow_nil: true, prefix: true

  after_create :add_owner

  class << self
    def access_roles
      Gitlab::Access.options_with_owner
    end
  end

  def to_param
    path
  end

  def add_users(user_ids, access)
    user_ids = user_ids.compact if user_ids.is_a?(Array)
    user_ids.each do |user_id|
      user_id = user_id.id if user_id.is_a? User
      team_user_relationships.create(user_id: user_id, team_access: access)
    end
  end

  def remove_user(user)
    team_user_relationships.where(user_id: user).destroy_all
  end

  def access_for entity
    begin
      case entity
      when User
        team_user_relationships.find_by(user_id: entity).team_access
      when Project
        team_project_relationships.find_by(project_id: entity).greatest_access
      when Group
        team_group_relationships.find_by(group_id: entity).greatest_access
      end
    rescue
      0
    end
  end

  def human_access_for entity
    begin
      case entity
      when User
        team_user_relationships.find_by(user_id: entity).human_access
      when Project
        team_project_relationships.find_by(project_id: entity).human_access
      when Group
        team_group_relationships.find_by(group_id: entity).human_access
      else
        "None"
      end
    rescue
      "None"
    end
  end

  private

  def add_owner
    self.add_users([creator.id], Team::OWNER)
  end
end
