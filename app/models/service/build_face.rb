class Service::BuildFace < Service

  attr_accessible :project_id, :project_url, :token, :type, :public_state_event, :active_state_event, :state_event

  delegate :execute, to: :service_hook, prefix: nil

  has_one :configuration, as: :service, class_name: Service::Configuration::BuildFace

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    after_transition on: :enable,   do: [:notify_build_face, :compose_service_hook, :add_service_keys]
    after_transition on: :disabled, do: :remove_service_keys

    state :enabled

    state :disabled
  end

  alias :activated? :enabled?

  def self.service_name
    'build_face'
  end

  def to_param
    self.class.service_name
  end

  def title
    read_attribute(:title) || 'Build face'
  end

  def description
    read_attribute(:description) || 'Build face service'
  end

  def fields
    [

    ]
  end

  def execute

  end

  def notify_build_face(action)
    action = "created" if action.is_a? StateMachine::Transition

    url = "#{Gitlab.config.services.build_face.domain}/#{Gitlab.config.services.build_face.system_hook_path}"
    data = {
      action: action,
      repository: {
        id: project.id,
        path: project.path_with_namespace,
        name: project.name_with_namespace,
        url: project.ssh_url_to_repo,
        description: project.description,
        homepage: project.http_url_to_repo
      }
    }

    if project.repository.nil?
      data[:repository][:branches] = project.repository.branches.map {|br| br.name}
      data[:repository][:tags] = project.repository.tags.map {|t| t.name}
    end

    #WebHook.post(url, body: data.to_json, headers: { "Content-Type" => "application/json" })
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = "#{Gitlab.config.services.build_face.domain}/#{Gitlab.config.services.build_face.web_hook_path}"
    hook.save
  end

  def add_service_keys
    options = :clone
    if pattern.present?
      import_service_keys pattern
    else
      add_service_key(Gitlab.config.services.build_face.service_keys.production.title, Gitlab.config.services.build_face.service_keys.production.key, options)
      add_service_key(Gitlab.config.services.build_face.service_keys.staging.title, Gitlab.config.services.build_face.service_keys.staging.key, options)
    end
  end

  def remove_service_keys
    service_key_service_relationships.destroy_all
    #remove_service_key(Gitlab.config.services.build_face.service_keys.production.key)
    #remove_service_key(Gitlab.config.services.build_face.service_keys.staging.key)
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
    "#{Gitlab.config.services.build_face.domain}/#{project.path_with_namespace}"
  end

  def status_img_path
    "Here"
    #project_url + "/status.png?ref=" + project.default_branch
  end
end
