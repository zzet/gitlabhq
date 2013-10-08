class Service::Jenkins < Service
  include Servisable

  default_title       'Jenkins CI'
  default_description 'Continuous integration server from Jenkins'
  service_name        'jenkins'

  alias :activated? :enabled?

  def fields
    []
  end

  def execute
  end
end
