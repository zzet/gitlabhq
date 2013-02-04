class Legacy::Group < LegacyDb
  belongs_to :creator,
             :class_name => Legacy::User,
             :foreign_key => "user_id"

  has_many :committerships,
           :as => :committer,
           :dependent => :destroy
  has_many :participated_repositories,
           :through => :committerships,
           :source => :repository,
           :class_name => Legacy::Repository
  has_many :memberships,
           :dependent => :destroy
  has_many :members,
           :through => :memberships,
           :source => :user
  has_many :repositories,
           :as => :owner,
           :conditions => ["kind NOT IN (?)", Legacy::Repository::KINDS_INTERNAL_REPO],
           :dependent => :destroy
  has_many :cloneable_repositories,
           :as => :owner,
           :class_name => Legacy::Repository,
           :conditions => ["kind != ?", Legacy::Repository::KIND_TRACKING_REPO]
  has_many :projects,
           :as => :owner

  def self.all_participating_in_projects(projects)
    mainline_ids = projects.map do |project|
      project.repositories.mainlines.map{|r| r.id }
    end.flatten
    Legacy::Committership.groups.find(:all,
      :conditions => { :repository_id => mainline_ids }).map{|c| c.committer }.uniq
  end

  def all_related_project_ids
    all_project_ids = projects.map{|p| p.id }
    all_project_ids << repositories.map{|r| r.project_id }
    all_project_ids << committerships.map{|p| p.repository.project_id }
    all_project_ids.flatten!.uniq!
    all_project_ids
  end

  def to_param
    name
  end

  def to_param_with_prefix
    "+#{to_param}"
  end

  def title
    name
  end

  def breadcrumb_parent
    nil
  end

  # is this +user+ a member of this group?
  def member?(user)
    members.include?(user)
  end

  # returns the Role of +user+ in this group
  def role_of_user(candidate)
    if !candidate || candidate == :false
      return
    end
    membership = memberships.find_by_user_id(candidate.id)
    return unless membership
    membership.role
  end

  # is +candidate+ an admin in this group?
  def admin?(candidate)
    role_of_user(candidate) == Legacy::Role.admin
  end

  # is +candidate+ a committer (or admin) in this group?
  def committer?(candidate)
    [Legacy::Role.admin, Legacy::Role.member].include?(role_of_user(candidate))
  end

  def deletable?
    members.count <= 1 && projects.blank?
  end

  def events(page = 1, user = nil)
    Legacy::Event.visible_by(user).top.paginate(:all, :page => page,
                       :conditions => ["events.user_id in (:user_ids) and events.project_id in (:project_ids)", {
                                         :user_ids => members.map { |u| u.id },
                                         :project_ids => all_related_project_ids,
                                       }],
                       :order => "events.created_at desc",
                       :include => [:user, :project])
  end

  protected
    def downcase_name
      name.downcase! if name
    end
end
