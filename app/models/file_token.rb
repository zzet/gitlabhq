class FileToken < ActiveRecord::Base

  attr_accessible :file, :last_usage_at, :project_id, :token, :usage_count, :user_id

  belongs_to :user
  belongs_to :project

  validates :token, presence: true
  validates :project, presence: true, uniqueness: { scope: :file }
  validates :user, presence: true
  validates :file, presence: true

  scope :for_project, ->(project) { where(project_id: project) }

  def generate_token!
    self.token = Digest::MD5.hexdigest("#{project_id} #{file} #{Time.now}")
  end

end
