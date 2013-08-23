class DeployKeyServiceRelationship < ActiveRecord::Base
  attr_accessible :deploy_key_id, :service_id, :deploy_key

  belongs_to :service
  belongs_to :deploy_key
  has_one :project, through: :service

  validates :deploy_key, presence: true
  validates :deploy_key_id, uniqueness: { scope: [:service_id], message: "already exists in service" }
  #validates :deploy_key_id, uniqueness: { scope: [:project_id], message: "already exists in project" }

  validates :service, presence: true
end
