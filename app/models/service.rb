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

  attr_accessible :title, :token, :type, :active

  belongs_to :project
  has_one :service_hook
  has_many :deploy_key_service_relationships, dependent: :destroy
  has_many :deploy_keys, through: :deploy_key_service_relationships

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  validates :project_id, presence: true

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

  def add_deploy_key title, key
    deploy_key = DeployKey.find_by_key(key)

    if deploy_key
      if deploy_keys.where(deploy_key_id: deploy_key).blank?
        deploy_key_service_relationships.create(deploy_key: deploy_key)
      end
    else
      deploy_keys.create(title: title, key: key)
    end
  end

  def remove_deploy_key key
    key = DeployKey.find_by_key(key) unless key.is_a? DeployKey

    deploy_keys.where(deploy_key_id: key).destroy_all if key
  end
end
