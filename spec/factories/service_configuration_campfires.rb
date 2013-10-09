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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campfire_configuration, class: Service::Configuration::Campfire do
    subdomain "gitlab1"
    token 'secret_token'
    room 'developers'
  end
end
