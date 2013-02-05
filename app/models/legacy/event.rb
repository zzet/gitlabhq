class Legacy::Event < LegacyDb
  #include Gitorious::Messaging::Publisher

  MAX_COMMIT_EVENTS = 25

  belongs_to :user
  belongs_to :project
  belongs_to :target, :polymorphic => true
  has_many :events, :as => :target do
    def commits
      find(:all, {
          :limit => Legacy::Event::MAX_COMMIT_EVENTS + 1,
          :conditions => {:action => Legacy::Action::COMMIT}
        })
    end
  end
  has_many :feed_items, :dependent => :destroy

  scope :top, {
    :conditions => ['target_type != ?', 'Event'],
    :order => "events.created_at desc",
    :include => [:user, :project]
  }

  scope :excluding_commits, {:conditions => ["action != ?", Legacy::Action::COMMIT]}

  # So, it's apic fail... who even invent polymorphic associations.
  # but, it work's well
  scope :visible_by, Proc.new { |user|
    user = Legacy::User.new({ :id => 0, :is_admin => false }) unless user.is_a?(Legacy::User)
    {
      :conditions => [
        "events.target_type = :project and exists (
          select projects.id from projects
          where
            projects.id = events.target_id
            and (projects.private = :private
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
            ))
        )
        or events.target_type = :repository and exists (
          select repositories.id
          from repositories
          join projects on repositories.project_id = projects.id
          where
            repositories.id = events.target_id
            and (projects.private = :private
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
              where
                c.repository_id = repositories.id and
                (c.committer_type = :user and c.committer_id = :user_id
                or c.committer_type = :group and exists (
                  select u2.id
                  from users as u2
                  inner join memberships as m2 on m2.user_id = u2.id
                  where u2.id = :user_id and m2.group_id = c.committer_id)
                )
              ))
        )", {
          :project => "Project",
          :repository => "Repository",
          :user => "User",
          :group => "Group",
          :user_id => user.id,
          :private => false
        }
      ]
    } unless user.site_admin?
  }
  def has_commits?
    return false if self.action != Legacy::Action::PUSH
    !events.blank? && !events.commits.blank?
  end

  def single_commit?
    return false unless has_commits?
    return events.size == 1
  end

  def commit_event?
    action == Legacy::Action::COMMIT
  end

  def kind
    'commit'
  end

  def email=(an_email)
    if u = Legacy::User.find_by_email_with_aliases(an_email)
      self.user = u
    else
      self.user_email = an_email
    end
  end

  def git_actor
    @git_actor ||= find_git_actor
  end

  # Initialize a Grit::Actor object: If only the email is provided, we
  # will give back anything before '@' as name and email as email. If
  # both name and email is provided, we will give an Actor with both.
  # If a User object, an Actor with name and email
  def find_git_actor
    if user
      Grit::Actor.new(user.fullname, user.email)
    else
      a = Grit::Actor.from_string(user_email)
      if a.email.blank?
        return Grit::Actor.new(a.name.to_s.split('@').first, a.name)
      else
        return a
      end
    end
  end

  def email
    git_actor.email
  end

  def actor_display
    git_actor.name
  end

  def favorites_for_email_notification
    conditions = ["notify_by_email = ? and (notify_on_self_events = ? or user_id != ?) and users.suspended_at IS NULL", true, true, self.user_id]
    favorites = self.project.favorites.find(:all, :joins => :user, :conditions => conditions)
    # Find anyone who's just favorited the target, if it's watchable
    if self.target.respond_to?(:watchers)
      favorites += self.target.favorites.find(:all, :joins => :user, :conditions => conditions)
    end

    favorites.uniq
  end

  def notifications_disabled?
    @notifications_disabled || commit_event?
  end

  protected

  def user_email_set?
    !user_email.blank?
  end

  # Get a list of user ids who are watching the project and target of
  # this event, excluding the event creator (since he's probably not
  # interested in his own doings).
  def watcher_ids
    # Find all the watchers of the project
    watcher_ids = self.project.watchers.find(:all, :select => "users.id").map(&:id)
    # Find anyone who's just watching the target, if it's watchable
    if self.target.respond_to?(:watchers)
      watcher_ids += self.target.watchers.find(:all, :select => "users.id").map(&:id)
    end
    watcher_ids.uniq.select{|an_id| an_id != self.user_id }
  end
end
