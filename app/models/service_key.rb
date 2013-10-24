# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#

class ServiceKey < Key
  has_many :service_key_service_relationships, dependent: :destroy
  has_many :services, through: :service_key_service_relationships
  has_many :projects, through: :services

  def for_project?(project)
    projects.include?(project)
  end
end
