class Service::Nix < Service

  attr_accessible :project_id, :project_url, :title, :token, :type, :state_event

  delegate :execute, to: :service_hook, prefix: nil

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    after_transition on: :enable,   do: :add_service_keys
    after_transition on: :disabled, do: :remove_service_keys

    state :enabled

    state :disabled
  end

  alias :activated? :enabled?

  def self.service_name
    'nix'
  end

  def title
    'Nix'
  end

  def description
    'Nix'
  end

  def to_param
    self.class.service_name
  end

  def fields
    [

    ]
  end

  def execute

  end

  def add_service_keys
    options = :push
    add_service_key(Gitlab.config.services.nix.service_keys.production.title, Gitlab.config.services.nix.service_keys.production.key, options)
  end

  def remove_service_keys
    remove_service_key(Gitlab.config.services.nix.service_keys.production.key)
  end
end
