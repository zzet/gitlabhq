# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer          not null, primary key
#  project_id :integer          not null
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#

class ProtectedBranch < ActiveRecord::Base
  include Watchable
  include Gitlab::ShellAdapter

  attr_accessible :name, :project_id

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  watch do
    source watchable_name do
      from :create, to: :created
      from :destroy, to: :deleted
    end
  end

  def commit
    project.repository.commit(self.name)
  end
end
