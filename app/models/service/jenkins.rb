class Service::Jenkins < Service
  include Servisable

  default_title       'Jenkins CI'
  default_description 'Continuous integration server from Jenkins'
  service_name        'jenkins'

  def fields
    []
  end

  def execute(data)
  end
end
