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

class Service::PivotalTracker < Service
  include HTTParty

  default_title       'PivotalTracker'
  default_description 'Project Management Software (Source Commits Endpoint)'
  service_name        'pivotal_tracker'

  has_one :configuration, as: :service, class_name: Service::Configuration::PivotalTracker

  delegate :token, to: :configuration, prefix: false

  def execute(push)
    url = 'https://www.pivotaltracker.com/services/v5/source_commits'
    push[:commits].each do |commit|
      message = {
        'source_commit' => {
          'commit_id' => commit[:id],
          'author' => commit[:author][:name],
          'url' => commit[:url],
          'message' => commit[:message]
        }
      }
      PivotaltrackerService.post(
        url,
        body: message.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-TrackerToken' => token
        }
      )
    end
  end
end
