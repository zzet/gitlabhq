class ServiceKeyServiceRelationship < ActiveRecord::Base
  attr_accessible :service_key_id, :service_id, :service_key, :code_access_state, :code_access_state_event

  belongs_to :service
  belongs_to :service_key
  has_one :project, through: :service

  validates :service, presence: true
  validates :service_key, presence: true
  validates :service_key_id, uniqueness: { scope: [:service_id], message: "already exists in service" }

  state_machine :code_access_state, initial: :none do

    event :denied do
      transition [:clone, :push, :protected_push] => :none
    end

    event :download_access do
      transition [:none, :push, :protected_push] => :clone
    end

    event :safe_push_access do
      transition [:none, :clone, :protected_push] => :push
    end

    event :push_to_all_access do
      transition push: :protected_push
    end

    state :none
    state :clone
    state :push
    state :protected_push
  end
end
