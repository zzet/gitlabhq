class Service::Jenkins < Service::Base
  attr_accessible :project_id, :project_url, :title, :token, :type, :state_event

  delegate :execute, to: :service_hook, prefix: nil

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    after_transition on: :enable, do: :add_deploy_keys_to_project
    after_transition on: :disabled, do: :remove_deploy_keys_from_project

    state :enabled

    state :disabled
  end

  alias :activated? :enabled?

  def title
    'Jenkins CI'
  end

  def description
    'Continuous integration server from Jenkins'
  end

  def to_param
    'jenkins'
  end

  def fields
    [

    ]
  end

  def execute

  end

  def add_deploy_keys_to_project
    add_deploy_key(Gitlab.config.services.jenkins.deploy_keys.production.title, Gitlab.config.services.jenkins.deploy_keys.production.key)
    add_deploy_key(Gitlab.config.services.jenkins.deploy_keys.ci_61.title, Gitlab.config.services.jenkins.deploy_keys.ci_61.key)
  end

  def remove_deploy_keys_from_project
    remove_deploy_key(Gitlab.config.services.jenkins.deploy_keys.production.key)
    remove_deploy_key(Gitlab.config.services.jenkins.deploy_keys.ci_61.key)
  end
end
