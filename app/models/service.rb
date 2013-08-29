# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#

# To add new service you should build a class inherited from Service
# and implement a set of methods
class Service < ActiveRecord::Base
  include Watchable

  attr_accessible :title, :token, :type, :active, :service_key_service_relationships_attributes

  belongs_to :project
  has_one :service_hook

  has_many :service_key_service_relationships, dependent: :destroy
  has_many :service_keys, through: :service_key_service_relationships

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  accepts_nested_attributes_for :service_key_service_relationships, reject_if: :all_blank, allow_destroy: true

  validates :project, presence: true

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    state :enabled

    state :disabled
  end

  actions_to_watch [:created, :updated, :deleted]

  scope :with_project, ->(project){ where(project_id: project) }

  def add_service_key title, key, key_state
    service_key = ServiceKey.find_by_key(key)
    service_key = ServiceKey.create(title: title, key: key) unless service_key

    if service_key_service_relationships.where(service_key_id: service_key).blank?
      service_key_service_relationships.create(service_key: service_key, code_access_state: key_state)
    end
  end

  def remove_service_key key
    key = ServiceKey.find_by_key(key) unless key.is_a? ServiceKey

    service_key_service_relationships.where(service_key_id: key).destroy_all if key
  end

  def allowed_clone?
    code_access.clone?
  end

  def allowed_push?
    code_access.push?
  end

  def allowed_protected_push?
    code_access.protected_push?
  end

  def activated?
    active
  end

  def title
    # implement inside child
  end

  def description
    # implement inside child
  end

  def to_param
    # implement inside child
  end

  def fields
    # implement inside child
    []
  end

  def execute
    # implement inside child
  end
end
