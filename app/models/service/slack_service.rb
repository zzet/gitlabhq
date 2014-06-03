# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  recipients  :text
#  api_key     :string(255)
#

class Service::SlackService < Service
  default_title       'Slack'
  default_description 'A team communication tool for the 21st century'
  service_name        'slack'

  has_one :configuration, as: :service, class_name: Service::Configuration::Slack

  def execute(push_data)
    message = Service::SlackMessage.new(push_data.merge(
      project_url: project_url,
      project_name: project_name
    ))

    notifier = Slack::Notifier.new(configuration.subdomain, configuration.token)
    notifier.channel = configuration.room
    notifier.username = 'GitLab'
    notifier.ping(message.pretext, attachments: message.attachments)
  end

  private

  def project_name
    project.name_with_namespace.gsub(/\s/, '')
  end

  def project_url
    project.web_url
  end
end
