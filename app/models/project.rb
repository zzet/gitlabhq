# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  public                 :boolean          default(FALSE), not null
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  git_protocol_enabled   :boolean
#  last_activity_at       :datetime
#  imported               :boolean          default(FALSE), not null
#  last_pushed_at         :datetime
#  import_url             :string(255)
#

class Project < ActiveRecord::Base
  include Watchable
  include Gitlab::ShellAdapter
  include Gitlab::Access

  extend Enumerize

  ActsAsTaggableOn.strict_case_match = true

  attr_accessible :name, :path, :description, :issues_tracker, :label_list,
    :issues_enabled, :wall_enabled, :merge_requests_enabled, :snippets_enabled, :issues_tracker_id,
    :wiki_enabled, :git_protocol_enabled, :public, :import_url, :last_activity_at, :last_pushed_at, as: [:default, :admin]

  attr_accessible :namespace_id, :creator_id, as: :admin

  acts_as_taggable_on :labels, :issues_default_labels

  attr_accessor :new_default_branch

  # Relations
  belongs_to :creator,      foreign_key: "creator_id", class_name: "User"
  belongs_to :group,        foreign_key: "namespace_id", conditions: "type = 'Group'"
  belongs_to :namespace


  has_one :forked_project_link, dependent: :destroy, foreign_key: "forked_to_project_id"
  has_one :forked_from_project, through: :forked_project_link

  has_many :old_events,         class_name: OldEvent, dependent: :destroy
  has_one  :last_event,         class_name: OldEvent, order: 'old_events.created_at DESC', foreign_key: 'project_id'

  has_many :services

  has_many :merge_requests,     dependent: :destroy, foreign_key: "target_project_id"
  has_many :fork_merge_requests,dependent: :destroy, foreign_key: "source_project_id", class_name: MergeRequest
  has_many :issues,             dependent: :destroy, order: "state DESC, created_at DESC"
  has_many :milestones,         dependent: :destroy
  has_many :notes,              dependent: :destroy
  has_many :snippets,           dependent: :destroy, class_name: ProjectSnippet
  has_many :hooks,              dependent: :destroy, class_name: ProjectHook
  has_many :protected_branches, dependent: :destroy

  has_many :file_tokens,        dependent: :destroy

  has_many :team_project_relationships, dependent: :destroy
  has_many :teams,                      through: :team_project_relationships

  has_many :team_group_relationships,   through: :group
  has_many :group_teams,                through: :team_group_relationships, source: :team

  has_many :users, through: :users_projects, conditions: { users: { state: :active } }

  has_many :users_projects,           dependent: :destroy
  has_many :users_groups,             through: :group
  has_many :team_user_relationships,  through: :teams

  has_many :core_members,             through: :users_projects,          source: :user, conditions: { users: { state: :active } }
  has_many :groups_members,           through: :users_groups,            source: :user, conditions: { users: { state: :active } }
  has_many :teams_members,            through: :team_user_relationships, source: :user, conditions: { users: { state: :active } }

  has_many :deploy_keys_projects, dependent: :destroy
  has_many :deploy_keys, through: :deploy_keys_projects

  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :members, to: :team, prefix: true

  # Validations
  validates :creator, presence: true
  validates :description, length: { within: 0..2000 }
  validates :name, presence: true, length: { within: 0..255 },
            format: { with: Gitlab::Regex.project_name_regex,
                      message: "only letters, digits, spaces & '_' '-' '.' allowed. Letter or digit should be first" }
  validates :path, presence: true, length: { within: 0..255 },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter or digit should be first" }
  validates :issues_enabled, :wall_enabled, :merge_requests_enabled,
            :wiki_enabled, inclusion: { in: [true, false] }
  validates :issues_tracker_id, length: { within: 0..255 }

  validates :namespace, presence: true
  validates_uniqueness_of :name, scope: :namespace_id
  validates_uniqueness_of :path, scope: :namespace_id

  validates :import_url,
    format: { with: URI::regexp(%w(git http https)), message: "should be a valid url" },
    if: :import?

  validate :check_limit, on: :create

  watch do
    source watchable_name do
      from :create,   to: :created
      from :update,   to: :transfer,  conditions: -> { @source.namespace_id_changed? && @source.namespace_id != @changes[:namespace_id].first } do
        @event_data[:owner_changes] = @changes
      end
      from :update,   to: :updated,   conditions: -> { [:name, :path, :description, :creator_id, :default_branch, :issues_enabled, :wall_enabled, :merge_requests_enabled, :public, :issues_tracker, :issues_tracker_id].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :import,   to: :imported
      from :destroy,  to: :deleted
    end

    source :push do
      before do: -> { @target = @source.project }
      from :create,   to: :created_branch,  conditions: -> { @source.created_branch? }
      from :create,   to: :created_tag,     conditions: -> { @source.created_tag? }
      from :create,   to: :deleted_branch,  conditions: -> { @source.deleted_branch? }
      from :create,   to: :deleted_tag,     conditions: -> { @source.deleted_tag? }
      from :create,   to: :pushed,          conditions: -> { @actions.blank? }
    end

    source :issue do
      before do: -> { @target = @source.project }
      from :create,   to: :opened
      from :update,   to: :updated,    conditions: -> { @actions.count == 1 && [:title, :description, :branch_name].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :close,    to: :closed
      from :reopen,   to: :reopened
      from :destroy,  to: :deleted
    end

    source :milestone do
      before do: -> { @target = @source.project }
      from :create,   to: :created
      from :close,    to: :closed
      from :active,   to: :reopened
      from :destroy,  to: :deleted
    end

    source :merge_request do
      before do: -> { @target = @source.target_project }
      from :create,   to: :opened
      from :update,   to: :updated,    conditions: -> { @actions.count == 1 && [:title, :description, :branch_name].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :close,    to: :closed
      from :reopen,   to: :reopened
      from :merge,    to: :merged
    end

    source :project_snippet do
      before do: -> { @target = @source.project }
      from :create,   to: :created
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :note do
      before do: -> { @target = @source.project }
      from :create,   to: :commented_commit,          conditions: -> { @source.commit_id.present? }
      from :create,   to: :commented_merge_request,   conditions: [ unless: -> { @source.commit_id.present? }, if: -> { @source.noteable.present? && @source.noteable.is_a?(MergeRequest) }]
      from :create,   to: :commented_issue,           conditions: [ unless: -> { @source.commit_id.present? }, if: -> { @source.noteable.present? && @source.noteable.is_a?(Issue) }]
      from :create,   to: :commented,                 conditions: [ unless: -> { @source.commit_id.present? }, if: -> { @source.noteable.blank? } ]
    end

    source :project_hook do
      before do: -> { @target = @source.project }
      from :create,   to: :added
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :web_hook do
      before do: -> { @target = @source.project }
      from :create,   to: :created
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :protected_branch do
      before do: -> { @target = @source.project }
      from :create,   to: :protected
      from :destroy,  to: :unprotected
    end

    # TODO. Add services

    source :team_project_relationship do
      before do: -> { @target = @source.project }
      from :create,   to: :assigned
      from :destroy,  to: :resigned
    end

    source :users_project do
      before do: -> { @target = @source.project }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end
  end

  adjacent_targets [:group]

  # Scopes
  scope :without_user, ->(user)  { where("projects.id NOT IN (:ids)", ids: user.authorized_projects.map(&:id) ) }
  scope :with_user, ->(user)  { where(users_projects: { user_id: user } ) }
  scope :without_team, ->(team) { team.projects.present? ? where("projects.id NOT IN (:ids)", ids: team.projects.map(&:id)) : scoped  }
  scope :not_in_group, ->(group) { where("projects.id NOT IN (:ids)", ids: group.project_ids ) }
  scope :in_team, ->(team) { where("projects.id IN (:ids)", ids: team.projects.map(&:id)) }
  scope :in_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :in_group_namespace, -> { joins(:group) }
  scope :sorted_by_activity, -> { order("projects.last_activity_at DESC") }
  scope :sorted_by_push_date, -> { reorder("projects.last_pushed_at DESC") }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where("namespace_id != ?", user.namespace_id) }
  scope :public_via_http, -> { where(public: true) }
  scope :public_via_git, -> { where(git_protocol_enabled: true) }
  scope :public_only, -> { public_via_http }

  enumerize :issues_tracker, in: (Gitlab.config.issues_tracker.keys).append(:gitlab), default: :gitlab

  class << self
    def abandoned
      where('projects.last_pushed_at < ?', 6.months.ago)
    end

    def with_push
      includes(:old_events).where('old_events.action = ?', OldEvent::PUSHED)
    end

    def active
      joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
    end

    def search query
      joins(:namespace).where("projects.name LIKE :query OR projects.path LIKE :query OR namespaces.name LIKE :query OR projects.description LIKE :query", query: "%#{query}%")
    end

    def find_with_namespace(id)
      if id.include?("/")
        id = id.split("/")
        namespace = ::Namespace.find_by_path(id.first)
        return nil unless namespace

        where(namespace_id: namespace.id).find_by_path(id.second)
      else
        where(path: id, namespace_id: nil).last
      end
    end
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= ::Repository.new(path_with_namespace)
  end

  def saved?
    id && persisted?
  end

  def import?
    import_url.present?
  end

  def imported?
    imported
  end

  def check_limit
    unless creator.can_create_project?
      errors[:limit_reached] << ("Your own projects limit is #{creator.projects_limit}! Please contact administrator to increase it")
    end
  rescue
    errors[:base] << ("Can't check your ability to create project")
  end

  def to_param
    namespace.path + "/" + path
  end

  def web_url
    [Gitlab.config.gitlab.url, path_with_namespace].join("/")
  end

  def build_commit_note(commit)
    notes.new(commit_id: commit.id, noteable_type: "Commit")
  end

  def last_activity
    last_event
  end

  def last_activity_date
    last_activity_at || updated_at
  end

  def last_push
    old_events.where(action: 5).last
  end

  def last_push_date
    last_pushed_at || created_at
  end

  def project_id
    self.id
  end

  def issues_labels
    @issues_labels ||= (issues_default_labels + issues.tags_on(:labels)).uniq.sort_by(&:name)
  end

  def issue_exists?(issue_id)
    if used_default_issues_tracker?
      self.issues.where(iid: issue_id).first.present?
    else
      true
    end
  end

  def used_default_issues_tracker?
    self.issues_tracker == Project.issues_tracker.default_value
  end

  def can_have_issues_tracker_id?
    self.issues_enabled && !self.used_default_issues_tracker?
  end

  def gitlab_ci
    @gitlab_ci_service ||= services.where(type: Service::GitlabCi).first
  end

  def jenkins_ci
    @jenkins_ci_service ||= services.where(type: Service::Jenkins).first
  end

  def gitlab_ci?
    gitlab_ci.present? && gitlab_ci.enabled?
  end

  def jenkins_ci?
    jenkins_ci.present? && jenkins_ci.enabled?
  end

  def jenkins_ci_with_mr?
    jenkins_ci? && jenkins_ci.configuration && jenkins_ci.configuration.merge_request_enabled
  end

  # For compatibility with old code
  def code
    path
  end

  def items_for entity
    case entity
    when 'issue' then
      issues
    when 'merge_request' then
      merge_requests
    end
  end

  def owner
    if group
      group
    else
      namespace.try(:owner)
    end
  end

  def team_member_by_name_or_email(name = nil, email = nil)
    user = users.where("name like ? or email like ?", name, email).first
    users_projects.where(user: user) if user
  end

  # Get Team Member record by user id
  def team_member_by_id(user_id)
    users_projects.find_by_user_id(user_id)
  end

  def name_with_namespace
    @name_with_namespace ||= begin
                               if namespace
                                 namespace.human_name + " / " + name
                               else
                                 name
                               end
                             end
  end

  def path_with_namespace
    if namespace
      namespace.path + '/' + path
    else
      path
    end
  end

  def execute_hooks(data)
    hooks.each { |hook| hook.async_execute(data) }
  end

  def execute_services(data)
    services.each do |service|

      # Call service hook only if it is active
      service.execute(data) if service.enabled?
    end
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.repository.commits_between(oldrev, newrev).map(&:id)

    # Update code for merge requests into project between project branches
    mrs = self.merge_requests.opened.by_branch(branch_name).all
    # Update code for merge requests between project and project fork
    mrs += self.fork_merge_requests.opened.by_branch(branch_name).all

    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

    # Close merge requests
    mrs = self.merge_requests.opened.where(target_branch: branch_name).all
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| merge_request.merge!(user.id) }

    true
  end

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:path, "Invalid repository path")
    false
  end

  def empty_repo?
    !repository.exists? || repository.empty?
  end

  def ensure_satellite_exists
    self.satellite.create unless self.satellite.exists?
  end

  def satellite
    @satellite ||= Gitlab::Satellite::Satellite.new(self)
  end

  def repo
    repository.raw
  end

  def url_to_repo
    gitlab_shell.url_to_repo(path_with_namespace)
  end

  def namespace_dir
    namespace.try(:path) || ''
  end

  def repo_exists?
    @repo_exists ||= repository.exists?
  rescue
    @repo_exists = false
  end

  def open_branches
    all_branches = repository.branches

    if protected_branches.present?
      all_branches.reject! do |branch|
        protected_branches_names.include?(branch.name)
      end
    end

    all_branches
  end

  def protected_branches_names
    @protected_branches_names ||= protected_branches.map(&:name)
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    [Gitlab.config.gitlab.url, "/", path_with_namespace, ".git"].join('')
  end

  def git_url_to_repo
    [Gitlab.config.gitlab.git_url, "/", path_with_namespace, ".git"].join('')
  end

  # Check if current branch name is marked as protected in the system
  def protected_branch? branch_name
    protected_branches_names.include?(branch_name)
  end

  def forked?
    !(forked_project_link.nil? || forked_project_link.forked_from_project.nil?)
  end

  def personal?
    !group
  end

  def rename_repo
    old_path_with_namespace = File.join(namespace_dir, path_was)
    new_path_with_namespace = File.join(namespace_dir, path)

    if gitlab_shell.mv_repository(old_path_with_namespace, new_path_with_namespace)
      # If repository moved successfully we need to remove old satellite
      # and send update instructions to users.
      # However we cannot allow rollback since we moved repository
      # So we basically we mute exceptions in next actions
      begin
        gitlab_shell.mv_repository("#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
        gitlab_shell.rm_satellites(old_path_with_namespace)
        ensure_satellite_exists
        reset_events_cache
      rescue
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end
    else
      # if we cannot move namespace directory we should rollback
      # db changes in order to prevent out of sync between db and fs
      raise Exception.new('repository cannot be renamed')
    end
  end

  # Reset events cache related to this project
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when project was moved
  # * when project was renamed
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    OldEvent.where(project_id: self.id).
      order('id DESC').limit(100).
      update_all(updated_at: Time.now)
  end

  def project_member(user)
    users_projects.where(user_id: user).first
  end

  def default_branch
    @default_branch ||= repository.root_ref if repository.exists?
  end
end
