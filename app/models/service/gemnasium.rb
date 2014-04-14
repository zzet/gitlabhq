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

require "gemnasium/gitlab_service"

class Service::Gemnasium < Service
  default_title       'Gemnasium'
  default_description 'Gemnasium monitors your project dependencies and alerts you about updates and security vulnerabilities.'
  service_name        'gemnasium'

  has_one :configuration, as: :service, class_name: Service::Configuration::Gemnasium

  delegate :token, :api_key, to: :configuration, prefix: false

  def execute(push_data)
    ::Gemnasium::GitlabService.execute(
      ref: push_data[:ref],
      before: push_data[:before],
      after: push_data[:after],
      token: token,
      api_key: api_key,
      repo: repo_path
      )
  end

  def repo_path
    File.join(Gitlab.config.gitlab_shell.repos_path, "#{project.path_with_namespace}.git")
  end
end
