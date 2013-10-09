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
