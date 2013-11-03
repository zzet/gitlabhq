# == Schema Information
#
# Table name: service_configuration_build_faces
#
#  id               :integer          not null, primary key
#  service_id       :integer
#  service_type     :string(255)
#  token            :string(255)
#  domain           :string(255)
#  system_hook_path :string(255)
#  web_hook_path    :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'spec_helper'

describe Service::Configuration::BuildFace do
  pending "add some examples to (or delete) #{__FILE__}"
end
