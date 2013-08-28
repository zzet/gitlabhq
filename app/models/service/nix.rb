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

  def add_service_keys
    options = { clone_access: true, push_access: true, push_to_protected_access: true }
    add_service_key(Gitlab.config.services.nix.service_keys.production.title, Gitlab.config.services.nix.service_keys.production.key, options)
  end

  def remove_service_keys
    remove_service_key(Gitlab.config.services.nix.service_keys.production.key)
  end
end
