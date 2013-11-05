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

require "flowdock-git-hook"

class Service::Flowdock < Service
  default_title       'Flowdock'
  default_description 'Flowdock is a collaboration web app for technical teams.'
  service_name        'flowdock'

  has_one :configuration, as: :service, class_name: Service::Configuration::Flowdock

  delegate :token, to: :configuration, prefix: false

  def execute(push_data)
    repo_path = File.join(Gitlab.config.gitlab_shell.repos_path, "#{project.path_with_namespace}.git")
    ::Flowdock::Git.post(
      push_data[:ref],
      push_data[:before],
      push_data[:after],
      token: token,
      repo: repo_path,
      repo_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}",
      commit_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/%s",
      diff_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/compare/%s...%s",
      )
  end
end
