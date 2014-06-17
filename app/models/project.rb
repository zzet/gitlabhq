# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  git_protocol_enabled   :boolean
#  last_activity_at       :datetime
#  last_pushed_at         :datetime
#  import_url             :string(255)
#  visibility_level       :integer          default(0), not null
#  archived               :boolean          default(FALSE), not null
#  wiki_engine            :string(255)
#  wiki_external_id       :string(255)
#  import_status          :string(255)
#

class Project < ActiveRecord::Base
  include Watchable
  include ProjectsSearch
  include Gitlab::ShellAdapter
  include Gitlab::VisibilityLevel
  extend Enumerize

  default_value_for :archived, false
  default_value_for :issues_enabled, true
  default_value_for :merge_requests_enabled, true
  default_value_for :wiki_enabled, true
  default_value_for :wall_enabled, false
  default_value_for :snippets_enabled, true

  ActsAsTaggableOn.strict_case_match = true

  attr_accessible :name, :path, :description, :issues_tracker, :label_list, :category_list,
    :issues_enabled, :merge_requests_enabled, :snippets_enabled, :issues_tracker_id,
    :wiki_enabled, :visibility_level, :import_url, :last_activity_at, :last_pushed_at, :git_protocol_enabled,
    :wiki_engine, :wiki_external_id, as: [:default, :admin]

  attr_accessible :namespace_id, :creator_id, as: :admin

  acts_as_taggable_on :labels, :issues_default_labels, :categories

  attr_accessor :new_default_branch

  # Relations
  belongs_to :creator,      foreign_key: "creator_id", class_name: "User"
  belongs_to :group, -> { where(type: Group) }, foreign_key: "namespace_id"
  belongs_to :namespace

  has_one :forked_project_link, dependent: :destroy, foreign_key: "forked_to_project_id"
  has_one :forked_from_project, through: :forked_project_link

  has_one :last_event, -> { events.order(created_at: :desc) }, class_name: Event, as: :target
  has_many :events, class_name: Event, as: :target

  has_many :services,           dependent: :destroy

  # Merge Requests for target project should be removed with it
  has_many :merge_requests,     dependent: :destroy, foreign_key: "target_project_id"
  # Merge requests from source project should be kept when source project was removed
  has_many :fork_merge_requests, foreign_key: "source_project_id", class_name: MergeRequest

  has_many :issues,   -> { order "state DESC, created_at DESC" }, dependent: :destroy
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

  has_many :users,                      -> { where({ users: { state: :active } }) },
                                        through: :users_projects

  has_many :users_projects,           dependent: :destroy
  has_many :users_groups,             through: :group
  has_many :team_user_relationships,  through: :teams

  has_many :core_members,             -> { where({ users: { state: :active } })}, through: :users_projects, source: :user
  has_many :groups_members,           -> { where({ users: { state: :active } })}, through: :users_groups, source: :user
  has_many :teams_members,            -> { where({ users: { state: :active } })}, through: :team_user_relationships, source: :user

  has_many :deploy_keys_projects, dependent: :destroy
  has_many :deploy_keys, through: :deploy_keys_projects

  delegate :name,    to: :owner, prefix: true, allow_nil: true
  delegate :members, to: :team,  prefix: true

  # Validations
  validates :creator, presence: true, on: :create
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :name, presence: true, length: { within: 0..255 },
            format: { with: Gitlab::Regex.project_name_regex,
                      message: "only letters, digits, spaces & '_' '-' '.' allowed. Letter or digit should be first" }
  validates :path, presence: true, length: { within: 0..255 },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter or digit should be first" }
  validates :issues_enabled, :merge_requests_enabled,
            :wiki_enabled, inclusion: { in: [true, false] }
  validates :issues_tracker_id, length: { maximum: 255 }, allow_blank: true
  validates :namespace, presence: true
  validates_uniqueness_of :name, scope: :namespace_id
  validates_uniqueness_of :path, scope: :namespace_id
  validates :import_url,
    format: { with: URI::regexp(%w(git http https)), message: "should be a valid url" },
    if: :import?
  validate :check_limit, on: :create

  watch do
    source watchable_name do
      title 'Project'
      description 'Notify about project destroy. Settings, owner, team updates.'
      from :create,   to: :created
      from :update,   to: :transfer,  conditions: -> { @source.namespace_id_changed? && @source.namespace_id != @changes[:namespace_id].first } do
        @event_data[:owner_changes] = @changes
      end
      from :update,   to: :updated,   conditions: -> { [:name, :path, :description, :creator_id, :default_branch, :issues_enabled, :merge_requests_enabled, :public, :issues_tracker, :issues_tracker_id].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :destroy,  to: :deleted

      # Mass actions
      from :import,             to: :imported
      from :memberships_add,    to: :members_added
      from :teams_add,          to: :teams_added
      from :memberships_remove, to: :members_removed
      from :memberships_update, to: :members_updated
    end

    source :push do
      title 'Pushes/branches/tags'
      description 'Notify about diffs. Tags, branches create/delete.'
      before do: -> { @target = @source.project }
      from :create,   to: :created_branch,  conditions: -> { @source.created_branch? }
      from :create,   to: :created_tag,     conditions: -> { @source.created_tag? }
      from :create,   to: :deleted_branch,  conditions: -> { @source.deleted_branch? }
      from :create,   to: :deleted_tag,     conditions: -> { @source.deleted_tag? }
      from :create,   to: :pushed,          conditions: -> { @actions.count == 1 }
    end

    source :issue do
      title 'Issues'
      description "Notify about new issues and it's updates."
      before do: -> { @target = @source.project }
      from :create,   to: :opened
      from :update,   to: :updated,    conditions: -> { @actions.count == 1 && [:title, :description, :branch_name].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :close,    to: :closed
      from :reopen,   to: :reopened
      from :destroy,  to: :deleted
    end

    source :milestone do
      title 'Milestones'
      description "Notify about new milestones and it's updates."
      before do: -> { @target = @source.project }
      from :create,   to: :created
      from :close,    to: :closed
      from :active,   to: :reopened
      from :destroy,  to: :deleted
    end

    source :merge_request do
      title 'Merge requests'
      description "Notify about new merge requests and it's updates."
      before do: -> { @target = @source.target_project }
      from :create,   to: :opened
      from :update,   to: :updated,    conditions: -> { @actions.count == 1 && [:title, :description, :branch_name].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :close,    to: :closed
      from :reopen,   to: :reopened
      from :merge,    to: :merged
    end

    source :project_snippet do
      title 'Snippets'
      description "Notify about new snippets and it's updates."
      before do: -> { @target = @source.project }
      from :create,   to: :created
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :note do
      title 'Notes'
      description "Notify about comments."
      before do: -> { @target = @source.project }
      from :create,   to: :commented_commit,          conditions: -> { @source.commit_id.present? }
      from :create,   to: :commented_merge_request,   conditions: [ unless: -> { @source.commit_id.present? }, if: -> { @source.noteable.present? && @source.noteable.is_a?(MergeRequest) }]
      from :create,   to: :commented_issue,           conditions: [ unless: -> { @source.commit_id.present? }, if: -> { @source.noteable.present? && @source.noteable.is_a?(Issue) }]
      from :create,   to: :commented,                 conditions: [ unless: -> { @source.commit_id.present? }, if: -> { @source.noteable.blank? } ]
    end

    source :project_hook do
      title 'Project hook'
      description 'Notify about add/delete project hooks.'
      before do: -> { @target = @source.project }
      from :create,   to: :added
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :web_hook do
      title 'Web hook'
      description 'Notify about add/delete web hooks.'
      before do: -> { @target = @source.project }
      from :create,   to: :created
      from :update,   to: :updated
      from :destroy,  to: :deleted
    end

    source :protected_branch do
      title 'Protected branches'
      description 'Notify about add/delete protected branches.'
      before do: -> { @target = @source.project }
      from :create,   to: :protected
      from :destroy,  to: :unprotected
    end

    # TODO. Add services

    source :team_project_relationship do
      title 'Team assignation/resignation'
      description 'Notify about Team assignation/resignation to project.'
      before do: -> { @target = @source.project }
      from :create,   to: :assigned
      from :destroy,  to: :resigned
    end

    source :users_project do
      title "Membership's actions"
      description 'Notify about users join/left from project.'
      before do: -> { @target = @source.project }
      from :create,   to: :joined
      from :update,   to: :updated
      from :destroy,  to: :left
    end
  end

  adjacent_targets [:group]

  # Scopes
  scope :without_user,  ->(user) { where.not(id: user.authorized_projects.pluck(:id) ) }
  scope :with_user,     ->(user) { where(users_projects: { user_id: user } ) }
  scope :without_team,  ->(team) { team.projects.present? ? where.not(id: team.projects.pluck(:id)) : all }
  scope :not_in_group, ->(group) { where.not(id: group.project_ids ) }
  scope :in_team,       ->(team) { where(id: team.projects.pluck(:id)) }
  scope :in_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :in_group_namespace,  -> { joins(:group) }
  scope :sorted_by_activity,  -> { order(last_activity_at: :desc) }
  scope :sorted_by_push_date, -> { reorder("projects.last_pushed_at DESC NULLS LAST") }
  scope :personal,      ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined,        ->(user) { where.not(namespace_id: user.namespace_id) }
  scope :public_via_git,      -> { where(git_protocol_enabled: true) }
  scope :public_only,         -> { where(visibility_level: PUBLIC) }
  scope :public_and_internal_only, -> { where(visibility_level: Project.public_and_internal_levels) }
  scope :public_or_internal_only, ->(user) { where(visibility_level: (user ? [ INTERNAL, PUBLIC ] : [ PUBLIC ])) }
  scope :non_archived,        -> { where(archived: false) }

  enumerize :issues_tracker, in: (Gitlab.config.issues_tracker.keys).append(:gitlab), default: (Gitlab.config.default_issues_tracker || :gitlab)
  enumerize :wiki_engine, in: (Gitlab.config.wiki_engine.keys).append(:gitlab), default: (Gitlab.config.default_wiki_engine || :gitlab)

  state_machine :import_status, initial: :none do
    event :import_start do
      transition :none => :started
    end

    event :import_finish do
      transition :started => :finished
    end

    event :import_fail do
      transition :started => :failed
    end

    event :import_retry do
      transition :failed => :started
    end

    state :started
    state :finished
    state :failed

    after_transition any => :started, :do => :add_import_job
  end

  class << self
    def public_and_internal_levels
      [Project::PUBLIC, Project::INTERNAL]
    end

    def abandoned
      where('projects.last_pushed_at < ?', 6.months.ago)
    end

    def publicish(user)
      visibility_levels = [Project::PUBLIC]
      visibility_levels += [Project::INTERNAL] if user
      where(visibility_level: visibility_levels)
    end

    def with_push
      includes(:old_events).where('old_events.action = ?', OldEvent::PUSHED)
    end

    def active
      joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
    end

    def search_by_title query
      where("projects.archived = ?", false).where("LOWER(projects.name) LIKE :query", query: "%#{query.downcase}%")
    end

    def find_with_namespace(id)
      return nil unless id.include?("/")

      id = id.split("/")
      namespace = Namespace.find_by(path: id.first)
      return nil unless namespace

      where(namespace_id: namespace.id).find_by(path: id.second)
    end

    def visibility_levels
      Gitlab::VisibilityLevel.options
    end

    def sort(method)
      case method.to_s
      when 'newest' then reorder('projects.created_at DESC')
      when 'oldest' then reorder('projects.created_at ASC')
      when 'recently_updated' then reorder('projects.updated_at DESC')
      when 'last_updated' then reorder('projects.updated_at ASC')
      when 'largest_repository' then reorder('projects.repository_size DESC')
      else reorder("namespaces.path, projects.name ASC")
      end
    end
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def owners
    team.owners
  end

  def masters
    team.masters
  end

  def developers
    team.developers
  end

  def reporters
    team.reporters
  end

  def guests
    team.guests
  end

  def repository
    @repository ||= ::Repository.new(path_with_namespace)
  end

  def saved?
    id && persisted?
  end

  def add_import_job
    RepositoryImportWorker.perform_in(2.seconds, id)
  end

  def import?
    import_url.present?
  end

  def imported?
    import_finished?
  end

  def import_in_progress?
    import? && import_status == 'started'
  end

  def import_failed?
    import_status == 'failed'
  end

  def import_finished?
    import_status == 'finished'
  end

  def check_limit
    unless creator.can_create_project?
      errors[:limit_reached] << ("Your project limit is #{creator.projects_limit} projects! Please contact your administrator to increase it")
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

  def web_url_without_protocol
    web_url.split("://")[1]
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

  # Tags are shared by issues and merge requests
  def issues_labels
    @issues_labels ||= (issues_default_labels +
                        merge_requests.tags_on(:labels) +
                        issues.tags_on(:labels)).uniq.sort_by(&:name)
  end

  def issue_exists?(issue_id)
    if issues_tracker.try(:to_sym) == :gitlab
      self.issues.where(iid: issue_id).first.present?
    else
      true
    end
  end

  def used_default_issues_tracker?
    self.issues_tracker == Project.issues_tracker.default_value
  end

  def can_have_issues_tracker_id?
    self.issues_enabled && self.issues_tracker.try(:to_sym) != :gitlab
  end

  def can_have_wiki_external_id?
    self.wiki_enabled && self.wiki_engine.try(:to_sym) != :gitlab
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

  def gemnasium
    @gemnasium_service ||= services.where(type: Service::Gemnasium).first
  end

  def gemnasium?
    gemnasium.present? && gemnasium.enabled?
  end

  def jenkins_ci?
    jenkins_ci.present? && jenkins_ci.enabled?
  end

  def jenkins_ci_with_mr?
    jenkins_ci? && jenkins_ci.configuration && jenkins_ci.configuration.merge_request_enabled
  end

  def ci_services
    services.select { |service| service.category == :ci }
  end

  def ci_service
    @ci_service ||= ci_services.select(&:activated?).first
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
    users_projects.find_by(user_id: user_id)
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

  def execute_hooks(data, hooks_scope = :push_hooks)
    hooks.send(hooks_scope).each do |hook|
      hook.async_execute(data)
    end
  end

  def execute_services(data)
    services.each do |service|

      # Call service hook only if it is active
      begin
        service.execute(data) if service.enabled?
      rescue
        # TODO. Add logging
      end
    end
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.repository.commits_between(oldrev, newrev).map(&:id)

    # Close merge requests
    mrs = self.merge_requests.opened.where(target_branch: branch_name).to_a
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| MergeRequestsService.new(user, merge_request).merge }

    # Update code for merge requests into project between project branches
    mrs = self.merge_requests.opened.by_branch(branch_name).to_a
    # Update code for merge requests between project and project fork
    mrs += self.fork_merge_requests.opened.by_branch(branch_name).to_a
    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

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

  def reload_default_branch
    @default_branch = nil
    default_branch
  end

  def visibility_level_field
    visibility_level
  end

  def archive!
    update_attribute(:archived, true)
  end

  def unarchive!
    update_attribute(:archived, false)
  end

  def change_head(branch)
    gitlab_shell.update_repository_head(self.path_with_namespace, branch)
    reload_default_branch
  end

  def forked_from?(project)
    forked? && project == forked_from_project
  end

  def update_repository_size
    update_attribute(:repository_size, repository.size)
  end
end
