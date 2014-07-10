# == Schema Information
#
# Table name: service_configuration_jenkins
#
#  id                    :integer          not null, primary key
#  service_id            :integer
#  service_type          :string(255)
#  host                  :string(255)
#  push_path             :string(255)
#  merge_request_path    :string(255)
#  branches              :text
#  merge_request_enabled :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Service::Configuration::Jenkins < ActiveRecord::Base
  attr_accessible :branches, :host, :merge_request_enabled, :merge_request_path, :push_path, :service_id

  belongs_to :service, polymorphic: true

  def fields
    [
      { type: 'text',     name: 'host',                   placeholder: 'http://ci01.undev.cc' },
      { type: 'text',     name: 'push_path',              placeholder: '/build/project' },
      { type: 'text',     name: 'merge_request_path',     placeholder: '/build/merge_request' },
      { type: 'text',     name: 'branches',               placeholder: 'master, develop, staging, release/.*, \A.*/foo\z' },
      { type: 'checkbox', name: 'merge_request_enabled',  placeholder: '' },
    ]
  end

  def branches_list
    return [] if branches.blank?
    branches.split(",").map do |branch|
      branch.strip
    end
  end

  def branches_regexp
    brs = branches_list
    bb = brs.map do |b|
      b = b.include?("\\A") ? b : "\\A#{b}"
      b.include?("\\z") ? b : "#{b}\\z"
    end.map do |b|
      b.gsub!("\\"){'\\'}
    end

    Regexp.union(bb.map{|b| Regexp.new(b)})
  end
end
