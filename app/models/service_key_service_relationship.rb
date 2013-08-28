class ServiceKeyServiceRelationship < ActiveRecord::Base
  attr_accessible :service_key_id, :service_id, :service_key, :clone_access, :push_access, :push_to_protected_access

  belongs_to :service
  belongs_to :service_key
  has_one :project, through: :service

  validates :service, presence: true
  validates :service_key, presence: true
  validates :service_key_id, uniqueness: { scope: [:service_id], message: "already exists in service" }
end
