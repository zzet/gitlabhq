# == Schema Information
#
# Table name: teams
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  path        :string(255)
#  owner_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :string(255)      default(""), not null
#

class Team < ActiveRecord::Base
  include Gitlab::Access
  include Watchable

  attr_accessible :name, :description, :creator_id, :path, :public

  belongs_to :creator, class_name: User

  has_many :team_project_relationships, dependent: :destroy
  has_many :team_user_relationships,    dependent: :destroy
  has_many :team_group_relationships,   dependent: :destroy

  has_many :projects,         through: :team_project_relationships
  has_many :groups,           through: :team_group_relationships
  has_many :groups_projects,  through: :groups, source: :projects
  has_many :members,          through: :team_user_relationships, source: :user, conditions: { users: { state: :active } }

  has_many :guests,           through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: Team::GUEST } }
  has_many :reporters,        through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: Team::REPORTER } }
  has_many :developers,       through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: Team::DEVELOPER } }
  has_many :masters,          through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: [Team::MASTER, Team::OWNER] } }
  has_many :owners,           through: :team_user_relationships, source: :user, conditions: { users: { state: :active }, team_user_relationships: { team_access: Team::OWNER } }

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  validates :creator, presence: true
  validates :name,    presence: true, uniqueness: true,
                      length: { within: 0..255 },
                      format: { with: Gitlab::Regex.name_regex,
                                message: "only letters, digits, spaces & '_' '-' '.' allowed." }
  validates :path,    presence: true, uniqueness: true, length: { within: 1..255 },
                      format: { with: Gitlab::Regex.path_regex,
                                message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :description, length: { within: 0..255 }

  scope :with_member,     ->(user)    { joins(:team_user_relationships).where(team_user_relationships: { user_id: user.id }) }
  scope :with_project,    ->(project) { joins(:team_project_relationships).where(team_project_relationships: { project_id: project })}
  scope :with_group,      ->(group)   { joins(:team_group_relationships).where(team_group_relationships: { group_id: group })}
  scope :without_project, ->(project) { where("teams.id NOT IN (:ids)", ids: (a = with_project(project); a.blank? ? 0 : a))}
  scope :created_by,      ->(user)    { where(creator_id: user) }

  delegate :name, to: :creator, allow_nil: true, prefix: true

  actions_to_watch [:created, :updated, :assigned, :reassigned, :deleted, :transfer]

  after_create :add_owner

  class << self
    def search query
      where("name LIKE :query OR path LIKE :query", query: "%#{query}%")
    end

    def access_roles
      Gitlab::Access.options_with_owner
    end
  end

  def to_param
    path
  end

  def admin?(member)
    member.admin? || admins.where(id: member).any?
  end

  def add_users(user_ids, access)
    user_ids.compact.each do |user_id|
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
        team_user_relationships.find_by_user_id(entity).team_access
      when Project
        team_project_relationships.find_by_project_id(entity).greatest_access
      when Group
        team_group_relationships.find_by_group_id(entity).greatest_access
      end
    rescue
      0
    end
  end

  def human_access_for entity
    begin
      case entity
      when User
        team_user_relationships.find_by_user_id(entity).human_access
      when Project
        team_project_relationships.find_by_project_id(entity).human_access
      when Group
        team_group_relationships.find_by_group_id(entity).human_access
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
