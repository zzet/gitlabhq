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

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = "#{Gitlab.config.services.jenkins.domain}/#{Gitlab.config.services.jenkins.web_hook_path}"
    hook.save
  end

  def add_deploy_keys_to_project
    if deploy_keys.count < 2
      deploy_key_from_production
    end
  end

  def deploy_key_from_production
    deploy_key = DeployKey.find_by_key(Gitlab.config.services.jenkins.deploy_keys.production.key)

    if deploy_key
      deploy_key_service_relationships.create(deploy_key: deploy_key)
    else
      deploy_keys.create(title: Gitlab.config.services.jenkins.deploy_keys.production.title,
                         key: Gitlab.config.services.jenkins.deploy_keys.production.key)
    end
  end

  def commit_status_path sha
    project_url + "/builds/#{sha}/status.json?token=#{token}"
  end

  def commit_status sha
    response = HTTParty.get(commit_status_path(sha))

    if response.code == 200 and response["status"]
      response["status"]
    else
      :error
    end
  end

  def build_page sha
    project_url + "/builds/#{sha}"
  end

  def project_path
    "#{Gitlab.config.services.jenkins.domain}/#{project.path_with_namespace}"
  end

  def status_img_path
    "Here"
    #project_url + "/status.png?ref=" + project.default_branch
  end
end
