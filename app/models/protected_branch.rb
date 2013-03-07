# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer          not null, primary key
#  project_id :integer          not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProtectedBranch < ActiveRecord::Base
  include Watchable
  include Gitlab::ShellAdapter

  attr_accessible :name

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, dependent: :destroy, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  actions_to_watch [:created, :updated, :deleted]

  def commit
    project.repository.commit(self.name)
  end
end
