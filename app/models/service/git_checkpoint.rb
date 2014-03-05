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
#

class Service::GitCheckpoint < Service
  default_title       "Git Checkpoint"
  default_description "Git Checkpoint service"
  service_name        "git_checkpoint"

  has_one :configuration, as: :service, class_name: Service::Configuration::GitCheckpoint

  state_machine :state, initial: :disabled do
    event :enable do
      transition [:disabled] => :enabled
    end

    event :disable do
      transition enabled: :disabled
    end

    after_transition on: :enable,   do: [:notify_git_checkpoint, :compose_service_hook]

    state :enabled
    state :disabled
  end

  def execute(data)
    compose_service_hook unless service_hook.present?
    service_hook.async_execute(data) if service_hook.present?
  end

  def notify_git_checkpoint(action)
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

    if project.repository.respond_to?(:raw)
      data[:repository][:branches] = project.repository.branches.map {|br| br.name}
      data[:repository][:tags] = project.repository.tags.map {|t| t.name}
    end

    begin
      result = WebHook.post(url, body: data.to_json, headers: { "Content-Type" => "application/json" })
      return result.success?
    rescue
      return false
    end
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = "#{configuration.domain}/#{configuration.web_hook_path}"
    hook.save
  end
end
