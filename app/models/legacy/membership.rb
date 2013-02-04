class Legacy::Membership < LegacyDb
  belongs_to :group
  belongs_to :user
  belongs_to :role

  has_many :messages, :as => :notifiable

  def breadcrumb_parent
    Breadcrumb::Memberships.new(group)
  end

  def title
    "Member"
  end

  protected
  def dont_demote_group_creator
    if user == group.creator and role == Role.member
      errors.add(:role, "The group creator cannot be denoted")
      return false
    end
  end

  def dont_delete_group_creator
    return user != group.creator
  end
end
