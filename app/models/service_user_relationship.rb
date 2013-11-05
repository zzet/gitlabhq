# == Schema Information
#
# Table name: service_user_relationships
#
#  id         :integer          not null, primary key
#  service_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ServiceUserRelationship < ActiveRecord::Base
  attr_accessible :service_id, :service,
                  :user_id,    :user

  belongs_to :service
  belongs_to :user
  has_one :project, through: :service

  validates :service, presence: true
  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:service_id], message: "already exists in service" }
end
