class Service::Configuration::BuildFace < ActiveRecord::Base
  attr_accessible :domain, :service_id, :service_type, :system_hook_path, :web_hook_path, :token

  belongs_to :service, polymorphic: true

  def fields
    [
      { type: 'text', name: 'domain',           placeholder: 'http://build-face.undev.cc' },
      { type: 'text', name: 'system_hook_path', placeholder: '/hooks/gitlab' },
      { type: 'text', name: 'web_hook_path',    placeholder: '/hooks' },
    ]
  end
end
