# == Schema Information
#
# Table name: service_configuration_hipchats
#
#  id           :integer          not null, primary key
#  service_id   :integer
#  service_type :string(255)
#  token        :string(255)
#  room         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe Service::Configuration::Hipchat do
  pending "add some examples to (or delete) #{__FILE__}"
end
