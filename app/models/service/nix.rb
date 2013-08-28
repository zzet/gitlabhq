class Service::Nix < Service::Base
  attr_accessible :project_id, :project_url, :title, :token, :type, :state_event

  delegate :execute, to: :service_hook, prefix: nil

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    after_transition :enabled, do: :add_service_keys_to_project
    state :enabled

    state :disabled
  end

  alias :activated? :enabled?

  def title
    'Nix'
  end

  def description
    'Nix'
  end

  def to_param
    'nix'
  end

  def fields
    [

    ]
  end

  def execute

  end

  def add_service_keys_to_project
    if service_keys.blank?
      service_key_from_production
    end
  end

  def service_key_from_production
    service_key = serviceKey.find_by_key(Gitlab.config.services.nix.service_keys.production.key)

    if service_key
      service_key_service_relationships.create(service_key: service_key)
    else
      service_keys.create(title: Gitlab.config.services.nix.service_keys.production.title,
                         key: Gitlab.config.services.nix.service_keys.production.key)
    end
  end
end
