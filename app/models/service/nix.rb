class Service::Nix < Service
  include Servisable

  default_title       'Nix'
  default_description 'Nix'
  service_name        'nix'

  alias :activated? :enabled?

  def fields
    []
  end

  def execute
  end
end
