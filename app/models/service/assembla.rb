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

class Service::Assembla < Service
  include HTTParty

  default_title       'Assembla'
  default_description 'Project Management Software (Source Commits Endpoint)'
  service_name        'assembla'

  has_one :configuration, as: :service, class_name: Service::Configuration::Assembla

  delegate :token, to: :configuration, prefix: false

  def execute(push)
    url = "https://atlas.assembla.com/spaces/#{subdomain}/github_tool?secret_key=#{token}"
    Service::Assembla.post(url,
                         body: { payload: push }.to_json,
                         headers: { 'Content-Type' => 'application/json' })
  end
end
