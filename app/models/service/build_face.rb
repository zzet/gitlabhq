class Service::BuildFace < Service
  include Servisable

  has_one :configuration, as: :service, class_name: Service::Configuration::BuildFace

  default_title       "Build Face"
  default_description "Build Face service"
  service_name        "build_face"

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    after_transition on: :enable,   do: [:notify_build_face, :compose_service_hook]

    state :enabled
    state :disabled
  end

  def execute(data)
    service_hook.async_execute(data)
  end

  def notify_build_face(action)
    action = "created" if action.is_a? StateMachine::Transition

    url = "#{configuration.domain}/#{configuration.system_hook_path}"
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
    hook.url = "#{configuration.domain}/#{configuration.web_hook_path}"
    hook.save
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
