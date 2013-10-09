class Service::Configuration::BuildFace < ActiveRecord::Base
  attr_accessible :domain, :service_id, :service_type, :system_hook_path, :web_hook_path, :token

  belongs_to :service, polymorphic: true
end
