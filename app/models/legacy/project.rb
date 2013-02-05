class Legacy::Project < LegacyDb
  #acts_as_taggable
  #include RecordThrottling
  #include UrlLinting
  #include Watchable
  #include Gitorious::Search

  belongs_to  :user
  belongs_to  :owner, :polymorphic => true

  has_many    :comments, :dependent => :destroy

  has_many    :repositories,
    :order => "repositories.created_at asc",
    :conditions => ["kind != ?", Legacy::Repository::KIND_WIKI],
    :dependent => :destroy
  has_one     :wiki_repository,
    :class_name => Legacy::Repository,
    :conditions => ["kind = ?", Legacy::Repository::KIND_WIKI],
    :dependent => :destroy
  has_many    :cloneable_repositories,
    :class_name => Legacy::Repository,
    :conditions => ["kind != ?", Legacy::Repository::KIND_TRACKING_REPO]
  has_many    :events,
    :order => "created_at asc",
    :dependent => :destroy
  has_many    :groups
  belongs_to  :containing_site,
    :class_name => Legacy::Site,
    :foreign_key => "site_id"
  has_many    :merge_request_statuses,
    :order => "id asc"
  accepts_nested_attributes_for :merge_request_statuses, :allow_destroy => true

  default_scope :conditions => ["projects.suspended_at is null"]

  scope :private, { :conditions => ["private = ?", true] }

  # Poor little mysql =(
  scope :visible_by, Proc.new { |user|
    user = Legacy::User.new({ :id => 0, :is_admin => false }) unless user.is_a?(Legacy::User)
    { :conditions => [
      "projects.private = :private
      or projects.owner_type = :user and projects.owner_id = :user_id
      or projects.owner_type = :group and exists (
        select u1.id
        from users as u1
        inner join memberships as m1 on m1.user_id = u1.id
        where u1.id = :user_id and m1.group_id = projects.owner_id
      )
      or exists (
        select c.id
        from committerships as c
        inner join repositories as r on c.repository_id = r.id
        where r.project_id = projects.id and (
          c.committer_type = :user and c.committer_id = :user_id
          or c.committer_type = :group and exists (
            select u2.id
            from users as u2
            inner join memberships as m2 on m2.user_id = u2.id
            where u2.id = :user_id and m2.group_id = c.committer_id
          )
        )
      )", {
      :user => 'User',
      :user_id => user.id,
      :group => 'Group',
      :private => false
    }]
    } unless user.site_admin?
  }

  serialize :merge_request_custom_states, Array

  attr_protected :owner_id, :user_id, :site_id

  def to_param
    slug
  end

  def to_param_with_prefix
    to_param
  end

  def site
    containing_site || Legacy::Site.default
  end

  def admin?(candidate)
    case owner
    when Legacy::User
      candidate == self.owner
    when Legacy::Group
      owner.admin?(candidate)
    end
  end

  def member?(candidate)
    case owner
    when Legacy::User
      candidate == self.owner
    when Legacy::Group
      owner.member?(candidate)
    end
  end

  def committer?(candidate)
    owner == Legacy::User ? owner == candidate : owner.committer?(candidate)
  end

  def owned_by_group?
    owner === Legacy::Group
  end

  def can_be_deleted_by?(candidate)
    admin?(candidate) && repositories.clones.count == 0
  end

  def stripped_description
    description.gsub(/<\/?[^>]*>/, "")
    # sanitizer = HTML::WhiteListSanitizer.new
    # sanitizer.sanitize(description, :tags => %w(str), :attributes => %w(class))
  end

  def descriptions_first_paragraph
    description[/^([^\n]+)/, 1]
  end

  def to_xml(opts = {})
    info = Proc.new { |options|
      builder = options[:builder]
      builder.owner(owner.to_param, :kind => (owned_by_group? ? "Team" : "User"))

      builder.repositories(:type => "array") do |repos|
        builder.mainlines :type => "array" do
          repositories.mainlines.each { |repo|
            builder.repository do
              builder.id repo.id
              builder.name repo.name
              builder.owner repo.owner.to_param, :kind => (repo.owned_by_group? ? "Team" : "User")
              builder.clone_url repo.clone_url
            end
          }
        end
        builder.clones :type => "array" do
          repositories.clones.each { |repo|
            builder.repository do
              builder.id repo.id
              builder.name repo.name
              builder.owner repo.owner.to_param, :kind => (repo.owned_by_group? ? "Team" : "User")
              builder.clone_url repo.clone_url
            end
          }
        end
      end
    }
    super({
      :procs => [info],
      :only => [:slug, :title, :description, :license, :home_url, :wiki_enabled,
        :created_at, :bugtracker_url, :mailinglist_url, :bugtracker_url],
    }.merge(opts))
  end

  def new_event_required?(action_id, target, user, data)
    events_count = events.count(:all, :conditions => [
                                "action = :action_id AND target_id = :target_id AND target_type = :target_type AND user_id = :user_id and data = :data AND created_at > :date_threshold",
                                {
      :action_id => action_id,
      :target_id => target.id,
      :target_type => target.class.name,
      :user_id => user.id,
      :data => data,
      :date_threshold => 1.hour.ago
    }])
    return events_count < 1
  end

  def breadcrumb_parent
    nil
  end
  def wiki_permissions
    wiki_repository.wiki_permissions
  end

  def wiki_permissions=(perms)
    wiki_repository.wiki_permissions = perms
  end

  # Returns a String representation of the merge request states
  def merge_request_states
    (merge_request_custom_states || merge_request_default_states).join("\n")
  end

  def merge_request_states=(s)
    self.merge_request_custom_states = s.split("\n").collect(&:strip)
  end

  def merge_request_fixed_states
    ['Merged','Rejected']
  end

  def merge_request_default_states
    ['Open','Closed','Verifying']
  end

  def has_custom_merge_request_states?
    !merge_request_custom_states.blank?
  end

  def default_merge_request_status_id
    if status = merge_request_statuses.default
      status.id
    end
  end

  def default_merge_request_status_id=(status_id)
    merge_request_statuses.each do |status|
      if status.id == status_id.to_i
        status.update_attribute(:default, true)
      else
        status.update_attribute(:default, false)
      end
    end
  end

  def suspended?
    !suspended_at.nil?
  end

  protected
  def downcase_slug
    slug.downcase! if slug
  end
end
