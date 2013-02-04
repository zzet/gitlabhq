#require 'digest/sha1'
#require_dependency "event"

class Legacy::User < LegacyDb
  #include UrlLinting

  has_many :projects
  has_many :memberships,
           :dependent => :destroy
  has_many :groups,
           :through => :memberships
  has_many :repositories,
           :as => :owner,
           :conditions => ["kind != ?", Legacy::Repository::KIND_WIKI],
           :dependent => :destroy
  has_many :cloneable_repositories,
           :class_name => Legacy::Repository,
           :conditions => ["kind != ?", Legacy::Repository::KIND_TRACKING_REPO]
  has_many :committerships,
           :as => :committer,
           :dependent => :destroy
  has_many :commit_repositories,
           :through => :committerships,
           :source => :repository,
           :conditions => ["repositories.kind NOT IN (?)", Legacy::Repository::KINDS_INTERNAL_REPO]
  has_many :ssh_keys, :order => "id desc",
           :dependent => :destroy
  has_many :comments
  has_many :email_aliases,
           :class_name => Legacy::Email,
           :dependent => :destroy
  has_many :events,
           :order => "events.created_at asc",
           :dependent => :destroy
  has_many :events_as_target,
           :class_name => Legacy::Event,
           :as => :target
  has_many :favorites,
           :dependent => :destroy
  has_many :feed_items,
           :foreign_key => "watcher_id"

  # Virtual attribute for the unencrypted password
  attr_accessor :password, :current_password

  attr_protected :login, :is_admin, :password, :current_password

  state_machine :aasm_state, :initial => :pending do
    state :terms_accepted

    event :accept_terms do
      transition :pending => :terms_accepted
    end
  end

  def can_write_to?(repository)
    repository.writable_by?(self)
  end

  def to_param
    login
  end

  def to_param_with_prefix
    "~#{to_param}"
  end

  def to_xml(opts = {})
    super({ :only => [:login, :created_at, :fullname, :url] }.merge(opts))
  end

  def to_json(opts = {})
    super({ :only => [:login, :created_at, :fullname, :url] }.merge(opts))
  end

  def is_openid_only?
    self.crypted_password.nil?
  end

  def suspended?
    !suspended_at.nil?
  end

  def site_admin?
    is_admin
  end

  # is +a_user+ an admin within this users realm
  # (for duck-typing repository etc access related things)
  def admin?(a_user)
    self == a_user
  end

  # is +a_user+ a committer within this users realm
  # (for duck-typing repository etc access related things)
  def committer?(a_user)
    self == a_user
  end

  def to_grit_actor
    Grit::Actor.new(fullname.blank? ? login : fullname, email)
  end

  def title
    fullname.blank? ? login : fullname
  end

  def in_openid_import_phase!
    @in_openid_import_phase = true
  end

  def in_openid_import_phase?
    return @in_openid_import_phase
  end

  def url=(an_url)
    self[:url] = clean_url(an_url)
  end

  def watched_objects(current_user = nil)
    favorites.visible_by(current_user).find(:all, { :order => "id desc" }).collect(&:watchable)
  end

  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      not_openid? && (crypted_password.blank? || !password.blank?)
    end

    def not_openid?
      identity_url.blank?
    end

    def make_activation_code
      return if !self.activated_at.blank?
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end

    def lint_identity_url
      return if not_openid?
      self.identity_url = OpenIdAuthentication.normalize_identifier(self.identity_url)
    rescue OpenIdAuthentication::InvalidOpenId
      # validate will catch it instead
    end

    def downcase_login
      login.downcase! if login
    end
end
