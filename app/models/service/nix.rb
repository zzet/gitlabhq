class Service::Nix < Service
  include Servisable

  default_title       'Nix'
  default_description 'Nix'
  service_name        'nix'

  def fields
    []
  end

  def execute
  end
end
