class DeployKey < Key
  has_many :deploy_keys_projects, dependent: :destroy
  has_many :projects, through: :deploy_keys_projects

  has_many :deploy_key_service_relationships, dependent: :destroy
  has_many :services, through: :deploy_key_service_relationships

  scope :in_projects, ->(projects) { joins(:deploy_keys_projects).where('deploy_keys_projects.project_id in (?)', projects) }

  def for_project?(project)
    projects.include?(project) || services.inject(false) { |res, s| res = res || (s.project == project) }
  end
end
