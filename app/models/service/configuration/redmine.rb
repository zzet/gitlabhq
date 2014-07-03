class Service::Configuration::Redmine < ActiveRecord::Base
  attr_accessible :domain, :service_id, :service_type, :web_hook_path

  belongs_to :service, polymorphic: true

  def fields
    [
      { type: 'text', name: 'domain',           placeholder: 'http://pm.undev.cc' },
      { type: 'text', name: 'web_hook_path',    placeholder: '/hooks' },
    ]
  end
end
