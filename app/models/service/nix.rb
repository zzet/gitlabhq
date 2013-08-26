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

  def add_deploy_keys_to_project
    if deploy_keys.blank?
      deploy_key_from_production
    end
  end

  def deploy_key_from_production
    deploy_key = DeployKey.find_by_key(Gitlab.config.services.nix.deploy_keys.production.key)

    if deploy_key
      deploy_key_service_relationships.create(deploy_key: deploy_key)
    else
      deploy_keys.create(title: Gitlab.config.services.nix.deploy_keys.production.title,
                         key: Gitlab.config.services.nix.deploy_keys.production.key)
    end
  end
end
