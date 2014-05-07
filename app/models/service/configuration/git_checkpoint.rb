# == Schema Information
#
# Table name: service_configuration_git_checkpoints
#
#  id               :integer          not null, primary key
#  service_id       :integer
#  service_type     :string(255)
#  token            :string(255)
#  domain           :string(255)
#  system_hook_path :string(255)
#  web_hook_path    :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class Service::Configuration::GitCheckpoint < ActiveRecord::Base
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
