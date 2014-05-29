# == Schema Information
#
# Table name: service_configuration_assemblas
#
#  id           :integer          not null, primary key
#  token        :string(255)
#  service_id   :integer
#  service_type :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe Service::Configuration::Assembla do
  pending "add some examples to (or delete) #{__FILE__}"
end
