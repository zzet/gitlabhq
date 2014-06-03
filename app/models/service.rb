# == Schema Information
#
# Table name: services
#
#  id                 :integer          not null, primary key
#  type               :string(255)
#  title              :string(255)
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  state              :string(255)
#  service_pattern_id :integer
#  public_state       :string(255)
#  active_state       :string(255)
#  description        :text
#  recipients         :text
#  api_key            :string(255)
#

# To add new service you should build a class inherited from Service
# and implement a set of methods
class Service < ActiveRecord::Base
  include Watchable

  attr_accessible :title, :description, :token, :type,
                  :public_state_event, :active_state_event, :state_event,
                  :service_key_service_relationships_attributes

  acts_as_tree parent_column_name: :service_pattern_id, dependent: :nullify

  belongs_to :project

  has_one :service_hook
  has_one :user,                      dependent: :destroy, through: :service_user_relationship
  has_one :service_user_relationship, dependent: :destroy

  has_many :service_key_service_relationships, dependent: :destroy
  has_many :service_keys, through: :service_key_service_relationships

  has_many :child_projects, through: :children, source: :project

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  accepts_nested_attributes_for :service_key_service_relationships, reject_if: :all_blank, allow_destroy: true

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

  state_machine :public_state, initial: :unpublished do
    event :publish do
      transition unpublished: :published
    end

    event :unpublish do
      transition published: :unpublished
    end

    state :published
    state :unpublished
  end

  state_machine :active_state, initial: :inactive do
    event :activate do
      transition [:inactive] => :active
    end

    event :deactivate do
      transition active: :inactive
    end

    after_transition on: :deactivate, do: :deactivate_childrens

    state :active
    state :inactive
  end

  scope :with_project, ->(project){ where(project_id: project) }
  scope :avaliable, -> { where(active_state: :active) }
  scope :public_list, -> { avaliable.where(public_state: :published) }

  class << self
    def implement_services
      @services ||= []
      if @services.blank?
        @services = self.direct_descendants
        if @services.blank?
          # In production class cache :)
          Dir[File.dirname(__FILE__) << "/service/*.rb"].each {|f| load f}
          @services = self.direct_descendants
        end
      end

      @services
    end

    def can_build?(param)
      service_name == param
    end

    def build_by_type(param, attrs = {})
      services = implement_services.map { |s| s if s.can_build?(param) }.compact

      if services.one?
        service = services.first.new(attrs)
        service.build_configuration if service.respond_to?(:configuration)
        return service
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    def default_title(attr)
      @title = attr
    end

    def title
      @title
    end

    def default_description(attr)
      @description = attr
    end

    def description
      @description
    end

    def service_name(attr = nil)
      return @service_name if attr.nil?
      @service_name = attr
    end

    def with_user(*args)
      @user_params = args.first
      raise ArgumentError, ":username must present!" if @user_params[:username].blank?
      @user_params[:password] = Devise.friendly_token.first(8) if @user_params[:password].blank?
    end

    def user_params
      @user_params || []
    end
  end

  def deactivate_childrens
    children.each do |child|
      child.disable
    end
  end

  def allowed_clone?(key)
    key_rel = service_key_service_relationships.where(service_key_id: key).first
    key_rel.clone? || key_rel.push? || key_rel.protected_push?
  end

  def allowed_push?(key)
    key_rel = service_key_service_relationships.where(service_key_id: key).first
    key_rel.push? || key_rel.protected_push?
  end

  def allowed_protected_push?(key)
    key_rel = service_key_service_relationships.where(service_key_id: key).first
    key_rel.protected_push?
  end

  def user_params
    self.class.user_params
  end

  def to_param
    read_attribute(:id) || self.class.service_name(nil)
  end

  def category
    :common
  end

  def title
    read_attribute(:title) || self.class.title
  end

  def description
    read_attribute(:description) || self.class.description
  end

  def service_name
    self.class.service_name
  end

  def help
    # implement inside child
  end

  def fields
    # implement inside child
    []
  end

  def execute(data)
    # implement inside child
  end

  def can_test?
    !project.empty_repo?
  end

  def pattern
    parent
  end

  def user
    pattern.present? ? pattern.user : super
  end
end
