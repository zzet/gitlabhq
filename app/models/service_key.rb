class ServiceKey < Key
  has_many :service_key_service_relationships, dependent: :destroy
  has_many :services, through: :service_key_service_relationships
  has_many :projects, through: :services

  def for_project?(project)
    projects.include?(project)
  end
end
