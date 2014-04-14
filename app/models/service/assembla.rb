# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  api_key     :string(255)
#

class Service::Assembla < Service
  include HTTParty

  default_title       'Assembla'
  default_description 'Project Management Software (Source Commits Endpoint)'
  service_name        'assembla'

  has_one :configuration, as: :service, class_name: Service::Configuration::Assembla

  delegate :token, to: :configuration, prefix: false

  def execute(push)
    url = "https://atlas.assembla.com/spaces/#{subdomain}/github_tool?secret_key=#{token}"
    Assembla.post(url, body: { payload: push }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
