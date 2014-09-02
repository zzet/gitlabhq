# == Schema Information
#
# Table name: users
#
#  id                       :integer          not null, primary key
#  email                    :string(255)      default(""), not null
#  encrypted_password       :string(255)      default(""), not null
#  reset_password_token     :string(255)
#  reset_password_sent_at   :datetime
#  remember_created_at      :datetime
#  sign_in_count            :integer          default(0)
#  current_sign_in_at       :datetime
#  last_sign_in_at          :datetime
#  current_sign_in_ip       :string(255)
#  last_sign_in_ip          :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  name                     :string(255)
#  admin                    :boolean          default(FALSE), not null
#  projects_limit           :integer          default(10)
#  skype                    :string(255)      default(""), not null
#  linkedin                 :string(255)      default(""), not null
#  twitter                  :string(255)      default(""), not null
#  authentication_token     :string(255)
#  theme_id                 :integer          default(1), not null
#  bio                      :string(255)
#  failed_attempts          :integer          default(0)
#  locked_at                :datetime
#  extern_uid               :string(255)
#  provider                 :string(255)
#  username                 :string(255)
#  can_create_group         :boolean          default(TRUE), not null
#  can_create_team          :boolean          default(TRUE), not null
#  state                    :string(255)
#  color_scheme_id          :integer          default(1), not null
#  notification_level       :integer          default(1), not null
#  password_expires_at      :datetime
#  created_by_id            :integer
#  last_credential_check_at :datetime
#  avatar                   :string(255)
#  confirmation_token       :string(255)
#  confirmed_at             :datetime
#  confirmation_sent_at     :datetime
#  unconfirmed_email        :string(255)
#  hide_no_ssh_key          :boolean          default(FALSE)
#  website_url              :string(255)      default(""), not null
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class User < ActiveRecord::Base
  include Watchable
  include Favouriteable
  include UsersSearch

  default_value_for :admin, false
  default_value_for :can_create_group, true
  default_value_for :can_create_team, false
  default_value_for :hide_no_ssh_key, false

  devise :database_authenticatable, :token_authenticatable, :lockable, :async,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :confirmable, :registerable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :bio, :name, :username,
                  :skype, :linkedin, :twitter, :website_url, :color_scheme_id, :theme_id, :force_random_password,
                  :extern_uid, :provider, :password_expires_at, :avatar, :hide_no_ssh_key,
                  as: [:default, :admin]

  attr_accessible :projects_limit, :can_create_group,
                  as: :admin

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  # Add login to attr_accessible
  attr_accessible :login

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where type: nil }, dependent: :destroy, foreign_key: :owner_id, class_name: "Namespace"

  # Profile
  has_many :keys, dependent: :destroy
  has_many :emails, dependent: :destroy

  # Groups
  has_many :users_groups,             dependent: :destroy
  has_many :groups,                   through: :users_groups
  has_many :owned_joined_groups,      -> { where(users_groups: { group_access: UsersGroup::OWNER } )}, through: :users_groups, source: :group
  has_many :masters_joined_groups,    -> { where(users_groups: { group_access: UsersGroup::MASTER } )}, through: :users_groups, source: :group
  has_many :created_groups,          class_name: Group, foreign_key: :owner_id

  # Projects
  has_many :users_projects,           dependent: :destroy

  has_many :projects,                 through: :users_projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :created_projects,         foreign_key: :creator_id, class_name: Project
  has_many :master_projects,          -> { where({ users_projects: { project_access: UsersProject::MASTER } })},
                                      through: :users_projects, source: :project

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id, class_name: Snippet
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id
  has_many :assigned_issues,          dependent: :destroy, foreign_key: :assignee_id, class_name: Issue
  has_many :assigned_merge_requests,  dependent: :destroy, foreign_key: :assignee_id, class_name: MergeRequest

  has_many :issues,                   dependent: :destroy, foreign_key: :author_id
  has_many :assigned_issues,          dependent: :destroy, foreign_key: :assignee_id, class_name: Issue

  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id
  has_many :assigned_merge_requests,  dependent: :destroy, foreign_key: :assignee_id, class_name: MergeRequest

  # Teams
  has_many :team_user_relationships,         dependent: :destroy
  has_many :teams,                           through: :team_user_relationships
  has_many :personal_teams,                  through: :team_user_relationships, foreign_key: :creator_id, source: :team
  has_many :owned_teams,                     -> { where( { team_user_relationships: { team_access: [Gitlab::Access::OWNER, Gitlab::Access::MASTER] } }) },
                                             through: :team_user_relationships, source: :team
  has_many :master_teams,                    -> { where( { team_user_relationships: { team_access: [Gitlab::Access::OWNER, Gitlab::Access::MASTER] } }) },
                                             through: :team_user_relationships, source: :team
  has_many :team_project_relationships,      through: :teams
  has_many :team_group_relationships,        through: :teams
  has_many :team_projects,                   through: :team_project_relationships,      source: :project
  has_many :team_groups,                     through: :team_group_relationships,        source: :group
  has_many :team_group_grojects,             through: :team_groups,                     source: :projects
  has_many :master_team_group_relationships, -> { where( { team_user_relationships: { team_access: [Gitlab::Access::OWNER, Gitlab::Access::MASTER] } })},
                                             through: :teams, source: :team_group_relationships
  has_many :master_team_groups,              through: :master_team_group_relationships, source: :group

  # Events
  has_many :events,                   dependent: :destroy, foreign_key: :author_id, class_name: Event
  has_many :personal_events,                               foreign_key: :author_id, class_name: Event
  has_many :recent_events,        -> { order(id: :desc) }, foreign_key: :author_id, class_name: Event
  has_many :old_events,               dependent: :destroy, foreign_key: :author_id, class_name: OldEvent

  # Notifications & Subscriptions
  has_many :personal_subscriptions,   dependent: :destroy, class_name: Event::Subscription
  has_many :auto_subscriptions,       dependent: :destroy, class_name: Event::AutoSubscription
  has_many :subscriptions,            dependent: :destroy, class_name: Event::Subscription, as: :target
  has_many :notifications,            dependent: :destroy, class_name: Event::Subscription::Notification, foreign_key: :subscriber_id
  has_one  :notification_setting,     dependent: :destroy, class_name: Event::Subscription::NotificationSetting

  has_many :summaries, class_name: Event::Summary, dependent: :destroy
  has_many :file_tokens

  # Favourites
  has_many :personal_favourites,      dependent: :destroy, class_name: Favourite
  has_many :favourited_projects,      through: :personal_favourites, source: :entity, source_type: Project
  has_many :favourited_groups,        through: :personal_favourites, source: :entity, source_type: Group
  has_many :favourited_teams,         through: :personal_favourites, source: :entity, source_type: Team
  has_many :favourited_users,         through: :personal_favourites, source: :entity, source_type: User

  #
  # Validations
  #
  validates :name, presence: true
  validates :email, presence: true, email: { strict_mode: true }, uniqueness: true
  validates :bio, length: { maximum: 255 }, allow_blank: true
  validates :extern_uid, allow_blank: true, uniqueness: {scope: :provider}
  validates :projects_limit, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.username_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }

  validate :namespace_uniq, if: ->(user) { user.username_changed? }
  validate :avatar_type, if: ->(user) { user.avatar_changed? }
  validate :unique_email, if: ->(user) { user.email_changed? }
  validate :corporate_email, if: ->(user) { user.email_changed? }
  validates :avatar, file_size: { maximum: 100.kilobytes.to_i }

  before_validation :generate_password, on: :create
  before_validation :sanitize_attrs

  before_save :ensure_authentication_token

  alias_attribute :private_token, :authentication_token

  delegate :path, to: :namespace, allow_nil: true, prefix: true

  state_machine :state, initial: :active do
    event :block do
      transition active: :blocked
    end

    event :activate do
      transition blocked: :active
    end
  end

  watch do
    source watchable_name do
      title 'User'
      description 'Notify about create, update, block, activate, destroy.'
      from :create,   to: :created
      from :block,    to: :blocked do
        @event_data[:teams]     = @source.teams.map { |t| t.attributes }
        @event_data[:groups]    = @source.groups.map { |t| t.attributes }
        @event_data[:projects]  = @source.projects.map { |pr| pr.attributes }
      end
      from :activate, to: :activate
      from :update,   to: :updated, conditions: -> { [:email, :name, :admin, :projects_limit, :skype, :linkedin, :twitter, :bio, :username, :can_create_group, :can_create_team, :avatar].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :destroy,  to: :deleted
    end

    source :users_group do
      title 'Group'
      description 'Notify about join/left group.'
      before do: -> { @target = @source.user }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end

    source :users_project do
      title 'Project'
      description 'Notify about join/left user.'
      before do: -> { @target = @source.user }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end

    source :team_user_relationship do
      title 'Team'
      description 'Notify about join/left team.'
      before do: -> { @target = @source.user }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end

    # TODO.
    # Add support with Issue, MergeRequest, Milestone, Note, Snippet
    # All models, which contain User
  end

  mount_uploader :avatar, AttachmentUploader

  # Scopes
  scope :admins, -> { where(admin:  true) }
  scope :blocked, -> { with_state(:blocked) }
  scope :active, -> { with_state(:active) }
  scope :alphabetically, -> { order('name ASC') }
  scope :in_team, ->(team){ where(id: team.member_ids) }
  scope :not_in_team, ->(team){ where('users.id NOT IN (:ids)', ids: team.member_ids) }
  scope :not_in_project, ->(project) { project.users.present? ? where.not(id: project.users.map(&:id)) : all }
  scope :not_in_group, ->(group) { group.users.present? ? where(id: group.users.pluck(:id)) : all }
  scope :without_projects, -> { where('id NOT IN (SELECT DISTINCT(user_id) FROM users_projects)') }
  scope :ldap, -> { where(provider:  'ldap') }

  scope :potential_team_members, ->(team) { team.members.any? ? active.not_in_team(team) : active  }

  #
  # Class methods
  #
  class << self
    # Devise method overridden to allow sign in with email or username
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
      else
        where(conditions).first
      end
    end

    def find_for_commit(email, name)
      # Prefer email match over name match
      User.where(email: email).first ||
        User.joins(:emails).where(emails: { email: email }).first ||
        User.where(name: name).first
    end

    def filter filter_name
      case filter_name
      when "admins"; self.admins
      when "blocked"; self.blocked
      when "wop"; self.without_projects
      else
        self.active
      end
    end

    def by_username_or_id(name_or_id)
      where('users.username = ? OR users.id = ?', name_or_id.to_s, name_or_id.to_i).first
    end

    def build_user(attrs = {}, options= {})
      if options[:as] == :admin
        User.new(defaults.merge(attrs.symbolize_keys), options)
      else
        User.new(attrs, options).with_defaults
      end
    end

    def defaults
      {
        projects_limit: Gitlab.config.gitlab.default_projects_limit,
        can_create_group: Gitlab.config.gitlab.default_can_create_group,
        theme_id: Gitlab.config.gitlab.default_theme
      }
    end
  end

  #
  # Instance methods
  #

  def to_param
    username
  end

  def notification
    @notification ||= Notification.new(self)
  end

  def generate_password
    if self.force_random_password
      self.password = self.password_confirmation = Devise.friendly_token.first(8)
    end
  end

  def namespace_uniq
    namespace_name = self.username
    if Namespace.find_by(path: namespace_name)
      self.errors.add :username, "already exists"
    end
  end

  # Groups where user is an owner
  def owned_groups
   @group_ids = owned_joined_groups.pluck(:id) +
     masters_joined_groups.pluck(:id) +
     master_team_groups.pluck(:id)
   Group.where(id: @group_ids)
  end

  def masters_groups
    masters_joined_groups
  end

  def owned_projects
    @project_ids ||= (Project.where(namespace_id: ([owned_groups.pluck(:id)] << [namespace.try(:id)]).flatten).pluck(:id) + master_projects.pluck(:id)).uniq
    Project.where(id: @project_ids).joins(:namespace)
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def unique_email
    self.errors.add(:email, 'has already been taken') if Email.exists?(email: self.email)
  end

  def corporate_email
    mail_domain = self.email.split("@").last
    self.errors.add(:email, 'email rejected. Invalid domain.') unless Gitlab.config.corporate_email_domains.include?(mail_domain)
  end

  # Groups user has access to
  def authorized_groups
    @authorized_groups ||= (self.admin? ? Group.all : personal_groups)
  end

  def personal_groups
    @group_ids ||= (groups.pluck(:id) + team_groups.pluck(:id) + authorized_projects.pluck(:namespace_id))
    Group.where(id: @group_ids).order('namespaces.name ASC')
  end

  def authorized_namespaces
    namespace_ids = owned_groups.pluck(:id) + [namespace.id]
    Namespace.where(id: namespace_ids)
  end

  # Projects user has access to
  def authorized_projects
    @authorized_projects ||= begin
                               project_ids = personal_projects.pluck(:id)
                               project_ids += projects.pluck(:id)
                               project_ids += owned_projects.pluck(:id)
                               project_ids += team_projects.pluck(:id)
                               project_ids += team_group_grojects.pluck(:id)
                               project_ids = project_ids.uniq

                               Project.where(id: project_ids).joins(:namespace).order('namespaces.name ASC')
                             end
  end

  def known_projects
    @project_ids ||= begin
                       project_ids = authorized_projects.pluck(:id)
                       project_ids += Project.public_or_internal_only(self).pluck(:id)
                       project_ids.uniq
                     end

    Project.where(id: @project_ids)
  end

  def authorized_teams
    ateams = Team.all
    unless self.admin?
      ateams = known_teams
    end
    ateams
  end

  def known_teams
    @known_teams_ids ||= (personal_teams.pluck(:id) + owned_teams.pluck(:id) +
                          master_teams.pluck(:id) + teams.pluck(:id) +
                          Team.where(public: true).pluck(:id)).uniq

    Team.where(id: @known_teams_ids)
  end

  def only_authorized_teams_ids
    ids = personal_teams.pluck(:id) + owned_teams.pluck(:id) +
        master_teams.pluck(:id) + teams.pluck(:id)
    ids.uniq
  end

  # Team membership in authorized projects
  def tm_in_authorized_projects
    UsersProject.where(project_id: authorized_projects.map(&:id), user_id: self.id)
  end

  def is_admin?
    admin
  end

  def require_ssh_key?
    keys.count == 0
  end

  def can_change_username?
    Gitlab.config.gitlab.username_changing_enabled
  end

  def can_create_project?
    projects_limit_left > 0
  end

  def can_create_group?
    can?(:create_group, nil)
  end

  def abilities
    @abilities ||= begin
                     abilities = Six.new
                     abilities << Ability
                     abilities
                   end
  end

  def can_select_namespace?
    several_namespaces? || admin
  end

  def can? action, subject
    abilities.allowed?(self, action, subject)
  end

  def first_name
    name.split.first unless name.blank?
  end

  def cared_merge_requests
    MergeRequest.cared(self)
  end

  def projects_limit_left
    projects_limit - personal_projects.count
  end

  def projects_limit_percent
    return 100 if projects_limit.zero?
    (personal_projects.count.to_f / projects_limit) * 100
  end

  def recent_push project_id = nil
    # Get push old_events not earlier than 2 hours ago
    events = recent_events.with_push.where("created_at > ?", Time.now - 2.hours)
    events = events.where(target_id: project_id, target_type: Project) if project_id

    # Take only latest one
    events = events.limit(1).first
  end

  def projects_sorted_by_activity
    authorized_projects.sorted_by_push_date
  end

  def several_namespaces?
    owned_groups.any?
  end

  def namespace_id
    namespace.try :id
  end

  def name_with_username
    "#{name} (#{username})"
  end

  def tm_of(project)
    project.team_member_by_id(self.id)
  end

  def already_forked? project
    !!fork_of(project)
  end

  def fork_of project
    links = ForkedProjectLink.where(forked_from_project_id: project, forked_to_project_id: personal_projects)

    if links.any?
      links.first.forked_to_project
    else
      nil
    end
  end

  def ldap_user?
    extern_uid && provider == 'ldap'
  end

  def accessible_deploy_keys
    DeployKey.in_projects(self.known_projects).uniq
  end

  def accessible_service_keys
    p "Fix accessible_service_keys !!!"
    ServiceKey.for_projects(self.known_projects).uniq
  end

  def created_by
    User.find_by(id: created_by_id) if created_by_id
  end

  def sanitize_attrs
    %w(name username skype linkedin twitter bio).each do |attr|
      value = self.send(attr)
      self.send("#{attr}=", Sanitize.clean(value)) if value.present?
    end
  end

  def requires_ldap_check?
    if ldap_user?
      !last_credential_check_at || (last_credential_check_at + 1.hour) < Time.now
    else
      false
    end
  end

  def solo_owned_groups
    @solo_owned_groups ||= owned_groups.select do |group|
      group.owners == [self]
    end
  end

  def with_defaults
    User.defaults.each do |k, v|
      self.send("#{k}=", v)
    end

    self
  end

  def can_leave_project?(project)
    project.namespace != namespace &&
      project.project_member(self)
  end

  # Reset project events cache related to this user
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when the user changes their avatar
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.where(author_id: self.id).
      order('id DESC').limit(1000).
      update_all(updated_at: Time.now)
  end

  def full_website_url
    return "http://#{website_url}" if website_url !~ /^https?:\/\//

    website_url
  end

  def short_website_url
    website_url.gsub(/https?:\/\//, '')
  end

  def all_ssh_keys
    keys.map(&:key)
  end

  def temp_oauth_email?
    email =~ /\Atemp-email-for-oauth/
  end

  def generate_tmp_oauth_email
    self.email = "temp-email-for-oauth-#{username}@gitlab.localhost"
  end

  def public_profile?
    authorized_projects.public_only.any?
  end

  def avatar_url(size = nil)
    if avatar.present?
      URI::join(Gitlab.config.gitlab.url, avatar.url).to_s
    else
      GravatarService.new.execute(email, size)
    end
  end
end
