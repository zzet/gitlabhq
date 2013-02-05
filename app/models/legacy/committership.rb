class Legacy::Committership < LegacyDb

  CAN_REVIEW = 1 << 4
  CAN_COMMIT = 1 << 5
  CAN_ADMIN  = 1 << 6

  PERMISSION_TABLE = {
    :review => CAN_REVIEW,
    :commit => CAN_COMMIT,
    :admin => CAN_ADMIN
  }

  belongs_to :committer, :polymorphic => true
  belongs_to :repository
  belongs_to :creator, :class_name => Legacy::User

  has_many :messages, :as => :notifiable

  scope :groups, :conditions => { :committer_type => "Group" }
  scope :users,  :conditions => { :committer_type => "User" }
  scope :reviewers, :conditions => ["(permissions & ?) != 0", CAN_REVIEW]
  scope :committers, :conditions => ["(permissions & ?) != 0", CAN_COMMIT]
  scope :admins, :conditions => ["(permissions & ?) != 0", CAN_ADMIN]

  def permission_mask_for(*perms)
    perms.inject(0) do |memo, perm_symbol|
      memo | PERMISSION_TABLE[perm_symbol]
    end
  end

  def build_permissions(*perms)
    perms = perms.flatten.compact.map{|p| p.to_sym }
    self.permissions = permission_mask_for(*perms)
  end

  def permitted?(wants_to)
    raise "unknown permission: #{wants_to.inspect}" if !PERMISSION_TABLE[wants_to]
    (self.permissions & PERMISSION_TABLE[wants_to]) != 0
  end

  def reviewer?
    permitted?(:review)
  end

  def committer?
    permitted?(:commit)
  end

  def admin?
    permitted?(:admin)
  end

  def permission_list
    PERMISSION_TABLE.keys.select{|perm| permitted?(perm) }
  end

  def breadcrumb_parent
    Breadcrumb::Committerships.new(repository)
  end

  def title
    new_record? ? "New collaborator" : "Collaborator"
  end

  # returns all the users in this committership, eg if it's a group it'll
  # return an array of the group members, otherwise a single-member array of
  # the user
  def members
    case committer
    when Legacy::Group
      committer.members
    else
      [committer]
    end
  end

  protected
    def notify_repository_owners
      return unless creator
      recipients = repository.owners
      recipients.each do |r|
        message = Legacy::Message.new({
          :sender => creator,
          :recipient => r,
          :subject => I18n.t("committership.notification_subject"),
          :body => I18n.t("committership.notification_body", {
            :inviter => creator.title,
            :user => committer.title,
            :repository => repository.name,
            :project => repository.project.title
          }),
          :notifiable => self
        })
        message.save
      end
    end

    def add_new_committer_event
      repository.project.create_event(Legacy::Action::ADD_COMMITTER, repository,
                                      creator, committer.title)
    end

    def add_removed_committer_event
      return unless repository
      repository.project.create_event(Legacy::Action::REMOVE_COMMITTER, repository,
                                      creator, committer.title)
    end

    def nullify_messages
      messages.update_all({:notifiable_id => nil, :notifiable_type => nil})
    end
end
