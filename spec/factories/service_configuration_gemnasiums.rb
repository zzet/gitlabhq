# == Schema Information
#
# Table name: service_configuration_assemblas
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
  factory :gemnasium_configuration, class: Service::Configuration::Gemnasium do
    service factory: :gemnasium_service
    token 'secret_token'
    api_key 'secret_key'
  end
end
