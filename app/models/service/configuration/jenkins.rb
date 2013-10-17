class Service::Configuration::Jenkins < ActiveRecord::Base
  attr_accessible :branches, :host, :merge_request_enabled, :merge_request_path, :push_path, :service_id

  belongs_to :service

  def fields
    [
      { type: 'text',     name: 'host',                   placeholder: 'http://ci01.undev.cc' },
      { type: 'text',     name: 'push_path',              placeholder: '/build/project' },
      { type: 'text',     name: 'merge_request_path',     placeholder: '/build/merge_request' },
      { type: 'text',     name: 'branches',               placeholder: 'master, develop, staging' },
      { type: 'checkbox', name: 'merge_request_enabled',  placeholder: '' },
    ]
  end
end
