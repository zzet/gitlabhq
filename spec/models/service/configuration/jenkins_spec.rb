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

require 'spec_helper'

describe Service::Configuration::Jenkins do
  pending "add some examples to (or delete) #{__FILE__}"
end
