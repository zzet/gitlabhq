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

class Service::GitlabCi < Service
  include Service::CiService

  default_title       'Gitlab CI'
  default_description 'Continuous integration server from GitLab'
  service_name        'gitlab_ci'

  has_one :configuration, as: :service, class_name: Service::Configuration::GitlabCi

  delegate :project_url, :token, to: :configuration, prefix: false

  after_save :compose_service_hook, if: :enabled?

  def execute(data)
    system_hook.execute(data)
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = [project_url, "/build", "?token=#{token}"].join("")
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

  def builds_path
    project_url + "?ref=" + project.default_branch
  end

  def status_img_path
    project_url + "/status.png?ref=" + project.default_branch
  end
end
