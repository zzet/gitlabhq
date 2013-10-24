# == Schema Information
#
# Table name: service_configuration_gitlab_cis
#
#  id           :integer          not null, primary key
#  service_id   :integer
#  service_type :string(255)
#  token        :string(255)
#  project_url  :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Service::Configuration::GitlabCi < ActiveRecord::Base
  attr_accessible :project_url, :token

  belongs_to :service, polymorphic: true

  validates :project_url, presence: true, if: :enabled?
  validates :token, presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'token', placeholder: 'GitLab CI project specific token' },
      { type: 'text', name: 'project_url', placeholder: 'http://ci.gitlabhq.com/projects/3'}
    ]
  end
end
