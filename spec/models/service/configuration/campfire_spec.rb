# == Schema Information
#
# Table name: service_configuration_campfires
#
#  id           :integer          not null, primary key
#  service_id   :integer
#  service_type :string(255)
#  token        :string(255)
#  subdomain    :string(255)
#  room         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe Service::Configuration::Campfire do
  pending "add some examples to (or delete) #{__FILE__}"
end
