# == Schema Information
#
# Table name: file_tokens
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  project_id    :integer
#  token         :string(255)
#  file          :string(255)
#  last_usage_at :datetime
#  usage_count   :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  source_ref    :string(255)
#

class FileToken < ActiveRecord::Base

  attr_accessible :file, :last_usage_at, :project_id, :token, :usage_count, :user_id, :source_ref

  belongs_to :user
  belongs_to :project

  validates :token, presence: true
  validates :project, presence: true
  validates :user, presence: true
  validates :file, presence: true, uniqueness: { scope: :project_id }
  validates :source_ref, presence: true

  scope :for_project, ->(project) { where(project_id: project) }

  def generate_token!
    self.token = Digest::MD5.hexdigest("#{project_id} #{file} #{Time.now}")
  end

end
